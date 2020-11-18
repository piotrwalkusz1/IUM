package com.piotrwalkusz.ium.backend.dto

import java.math.BigDecimal

data class CreateProductDto (
        val name: String,
        val manufacturer: String,
        val price: BigDecimal
)