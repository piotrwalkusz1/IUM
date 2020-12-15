package com.piotrwalkusz.ium.backend.dto

data class AddProductCommand(val data: CreateProductDto, val quantity: Int) : SynchronizationCommand {
}