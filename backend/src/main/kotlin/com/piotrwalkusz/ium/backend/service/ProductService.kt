package com.piotrwalkusz.ium.backend.service

import com.piotrwalkusz.ium.backend.model.Product
import com.piotrwalkusz.ium.backend.repository.ProductRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Service

@Service
class ProductService {

    @Autowired
    lateinit var productRepository: ProductRepository

    fun getProduct(id: String): Product {
        return productRepository.findById(id).get()
    }

    fun getProducts(): List<Product> {
        return productRepository.findAll()
    }

    fun saveProduct(product: Product): Product {
        return productRepository.save(product)
    }

    fun removeProduct(id: String) {
        productRepository.deleteById(id)
    }
}