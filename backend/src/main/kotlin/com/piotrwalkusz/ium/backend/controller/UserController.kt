package com.piotrwalkusz.ium.backend.controller

import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/users")
class UserController {

    @GetMapping("/current-user/roles")
    fun getCurrentUserRoles(): List<String> {
        return SecurityContextHolder.getContext().authentication.authorities.map { it.authority }
    }
}