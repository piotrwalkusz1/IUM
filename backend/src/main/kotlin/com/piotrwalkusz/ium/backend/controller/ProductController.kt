package com.piotrwalkusz.ium.backend.controller

import com.mongodb.client.MongoCollection
import com.mongodb.client.model.Filters
import com.mongodb.client.model.Updates
import com.piotrwalkusz.ium.backend.dto.*
import com.piotrwalkusz.ium.backend.model.Product
import com.piotrwalkusz.ium.backend.repository.ProductRepository
import com.piotrwalkusz.ium.backend.service.ProductService
import org.bson.Document
import org.bson.conversions.Bson
import org.bson.types.ObjectId
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.data.mongodb.core.FindAndModifyOptions
import org.springframework.data.mongodb.core.MongoOperations
import org.springframework.data.mongodb.core.MongoTemplate
import org.springframework.data.mongodb.core.query.*
import org.springframework.web.bind.annotation.*
import org.springframework.web.client.HttpClientErrorException
import javax.annotation.security.RolesAllowed
import kotlin.math.max
import org.springframework.http.HttpStatus
import javax.servlet.http.HttpServletRequest


@ResponseStatus(value = HttpStatus.BAD_REQUEST, reason = "Bad request")
class BadRequestException : RuntimeException()


@RestController
@RequestMapping("/api/products")
class ProductController {

    @Autowired
    lateinit var productService: ProductService

    @Autowired
    lateinit var productRepository: ProductRepository

    @Autowired
    lateinit var mongoTemplate: MongoTemplate

    @Autowired
    lateinit var mongoOperations: MongoOperations

    @GetMapping
    fun getProducts(): List<Product> {
        return productService.getProducts()
    }

    @PostMapping
    fun createProduct(@RequestBody productDto: CreateProductDto): Product {
        val product = Product(
                id = ObjectId().toString(),
                name = productDto.name,
                manufacturer = productDto.manufacturer,
                price = productDto.price,
                quantity = 0)

        return productService.saveProduct(product)
    }

    @PutMapping
    fun saveProduct(@RequestBody productDto: UpdateProductDto): Product {
        return updateProduct(productDto)!!
    }

    @PostMapping("/{productId}/quantity/increase")
    fun increaseProductQuantity(@PathVariable productId: String, @RequestBody delta: Int): Int {
        return increaseQuantity(productId, delta)!!.quantity
    }

    @PostMapping("/{productId}/quantity/decrease")
    fun decreaseProductQuantity(@PathVariable productId: String, @RequestBody delta: Int): Int {
        return decreaseQuantity(productId, delta)?.quantity ?: throw BadRequestException()
    }

    @RolesAllowed("ROLE_MANAGER")
    @DeleteMapping("/{productId}")
    fun removeProduct(@PathVariable productId: String) {
        productService.removeProduct(productId)
    }

    @PostMapping("/synchronize")
    fun synchronize(request: HttpServletRequest, @RequestBody synchronizationDto: SynchronizationDto): String {
        return synchronizationDto.commands.mapNotNull { executeCommand(it, request) }.joinToString("\n")
    }

    private fun executeCommand(command: SynchronizationCommand, request: HttpServletRequest): String? {
        when (command) {
            is AddProductCommand -> {
                val product = Product(
                        id = ObjectId().toString(),
                        name = command.data.name,
                        manufacturer = command.data.manufacturer,
                        price = command.data.price,
                        quantity = command.quantity)
                productService.saveProduct(product)
            }
            is RemoveProductCommand -> {
                if (request.isUserInRole("ROLE_MANAGER")) {
                    val result = mongoOperations.remove(findById(command.productId), Product::class.java)
                    if (result.deletedCount == 0L) {
                        return "Nie można usunąć produktu ${command.productId}. Produkt już nie istnieje."
                    }
                } else {
                    return "Nie można usunąć produktu ${command.productId}. Brak uprawnień."
                }
            }
            is UpdateProductCommand -> {
                val result = updateProduct(command.data)
                if (result == null) {
                    return "Nie można zmodyfikować produktu ${command.data.id}. Produkt już nie istnieje."
                }
            }
            is IncreaseQuantityCommand -> {
                val result = increaseQuantity(command.productId, command.delta)
                if (result == null) {
                    return "Nie można zwiększyć ilości produktu ${command.productId}. Produkt już nie istnieje."
                }
            }
            is DecreaseQuantityCommand -> {
                val result = decreaseQuantity(command.productId, command.delta)
                if (result == null) {
                    return "Nie można zmniejszyć ilości produktu ${command.productId}. Produkt już nie istnieje lub ilość produktów jest niewystarczająca."
                }
            }
        }

        return null
    }

    private fun increaseQuantity(productId: String, delta: Int): Product? {
        return mongoOperations.findAndModify(
                findById(productId),
                Update().inc("quantity", delta),
                FindAndModifyOptions.options().returnNew(true),
                Product::class.java)
    }

    private fun decreaseQuantity(productId: String, delta: Int): Product? {
        return mongoOperations.findAndModify(
                findById(productId).addCriteria(Criteria("quantity").gte(delta)),
                Update().inc("quantity", -delta),
                FindAndModifyOptions.options().returnNew(true),
                Product::class.java)
    }

    private fun updateProduct(product: UpdateProductDto): Product? {
        return mongoOperations.findAndModify(
                findById(product.id),
                Update()
                        .set("name", product.name)
                        .set("manufacturer", product.manufacturer)
                        .set("price", product.price),
                Product::class.java)
    }

    private fun findById(productId: String): Query {
        return Query(Criteria("_id").isEqualTo(productId))
    }

    private fun getCollection(): MongoCollection<Product> {
        return mongoTemplate.getCollection("product").withDocumentClass(Product::class.java)
    }
}