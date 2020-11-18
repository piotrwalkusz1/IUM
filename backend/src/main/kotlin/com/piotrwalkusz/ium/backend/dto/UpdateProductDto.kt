package com.piotrwalkusz.ium.backend.dto

import java.math.BigDecimal

data class UpdateProductDto(
        val id: String,
        val name: String,
        val manufacturer: String,
        val price: BigDecimal
)