package com.piotrwalkusz.ium.backend.dto

data class IncreaseQuantityCommand(val productId: String, val delta: Int) : SynchronizationCommand {
}