package com.piotrwalkusz.ium.backend.dto

data class RemoveProductCommand(val productId: String) : SynchronizationCommand {
}