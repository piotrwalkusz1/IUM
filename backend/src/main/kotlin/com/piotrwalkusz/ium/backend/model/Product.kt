package com.piotrwalkusz.ium.backend.model

import org.bson.types.ObjectId
import org.springframework.data.annotation.Id
import java.math.BigDecimal

data class Product(
        @Id
        val id: String,
        val name: String,
        val manufacturer: String,
        val price: BigDecimal,
        val quantity: Int
)