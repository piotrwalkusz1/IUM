package com.piotrwalkusz.ium.backend.dto

import com.fasterxml.jackson.annotation.JsonSubTypes
import com.fasterxml.jackson.annotation.JsonTypeInfo

@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, property = "type")
@JsonSubTypes(
        JsonSubTypes.Type(name = "Add", value = AddProductCommand::class),
        JsonSubTypes.Type(name = "Remove", value = RemoveProductCommand::class),
        JsonSubTypes.Type(name = "Increase", value = IncreaseQuantityCommand::class),
        JsonSubTypes.Type(name = "Decrease", value = DecreaseQuantityCommand::class),
        JsonSubTypes.Type(name = "Update", value = UpdateProductCommand::class)
)
interface SynchronizationCommand