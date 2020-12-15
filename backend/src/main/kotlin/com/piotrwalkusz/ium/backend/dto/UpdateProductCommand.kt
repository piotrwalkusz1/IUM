package com.piotrwalkusz.ium.backend.dto

data class UpdateProductCommand(val data: UpdateProductDto) : SynchronizationCommand {
}