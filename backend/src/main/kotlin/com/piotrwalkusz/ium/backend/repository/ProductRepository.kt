package com.piotrwalkusz.ium.backend.repository

import com.piotrwalkusz.ium.backend.model.Product
import org.springframework.data.mongodb.repository.MongoRepository

interface ProductRepository : MongoRepository<Product, String> {

}