package com.piotrwalkusz.ium.backend.controller

import com.piotrwalkusz.ium.backend.dto.CreateProductDto
import com.piotrwalkusz.ium.backend.dto.UpdateProductDto
import com.piotrwalkusz.ium.backend.model.Product
import com.piotrwalkusz.ium.backend.service.ProductService
import org.bson.types.ObjectId
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.web.bind.annotation.*
import javax.annotation.security.RolesAllowed
import kotlin.math.max


@RestController
@RequestMapping("/api/products")
class ProductController {

    @Autowired
    lateinit var productService: ProductService

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
        val originalProduct = productService.getProduct(productDto.id)

        return productService.saveProduct(originalProduct.copy(
                name = productDto.name,
                manufacturer = productDto.manufacturer,
                price = productDto.price))
    }

    @PostMapping("/{productId}/quantity/increase")
    fun increaseProductQuantity(@PathVariable productId: String, @RequestBody delta: Int): Int {
        val product = productService.getProduct(productId)
        val newQuantity = product.quantity + delta;

        productService.saveProduct(product.copy(quantity = newQuantity))

        return newQuantity
    }

    @PostMapping("/{productId}/quantity/decrease")
    fun decreaseProductQuantity(@PathVariable productId: String, @RequestBody delta: Int): Int {
        val product = productService.getProduct(productId)
        val newQuantity = max(0, product.quantity - delta)

        productService.saveProduct(product.copy(quantity = newQuantity))

        return newQuantity
    }

    @RolesAllowed("ROLE_MANAGER")
    @DeleteMapping("/{productId}")
    fun removeProduct(@PathVariable productId: String) {
        productService.removeProduct(productId)
    }
}