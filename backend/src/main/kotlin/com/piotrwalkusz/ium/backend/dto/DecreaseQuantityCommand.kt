package com.piotrwalkusz.ium.backend.dto

data class DecreaseQuantityCommand(val productId: String, val delta: Int) : SynchronizationCommand {
}