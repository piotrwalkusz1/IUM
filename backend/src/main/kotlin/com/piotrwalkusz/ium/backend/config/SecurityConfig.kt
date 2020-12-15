package com.piotrwalkusz.ium.backend.config

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator
import org.springframework.security.oauth2.core.OAuth2TokenValidator
import org.springframework.security.oauth2.jwt.*
import org.springframework.util.Assert
import java.util.ArrayList


@Configuration
@EnableWebSecurity
class SecurityConfig : WebSecurityConfigurerAdapter() {

    @Autowired
    fun configureGlobal(auth: AuthenticationManagerBuilder) {
        auth.inMemoryAuthentication()
                .withUser("user").password(passwordEncoder().encode("user"))
                .authorities("ROLE_MANAGER")
    }

    override fun configure(http: HttpSecurity) {
        http
                .authorizeRequests()
                .anyRequest()
                .authenticated()
                .and()
                .oauth2ResourceServer { oauth2ResourceServer ->
                    oauth2ResourceServer.jwt { jwt ->
                        val validator = DelegatingOAuth2TokenValidator(listOf(
                                JwtTimestampValidator(),
                                JwtIssuerValidator("https://accounts.google.com"),
                                JwtClaimValidator<Collection<String>>(JwtClaimNames.AUD) { it.contains("1021533878214-3gi11cjuibgsvlfr1t3jlqaj9ba1ajl8.apps.googleusercontent.com") }
                        ))
                        val jwtDecoder = NimbusJwtDecoder.withJwkSetUri("https://www.googleapis.com/oauth2/v3/certs").build()
                        jwtDecoder.setJwtValidator(validator)

                        jwt.decoder(jwtDecoder)
                    }
                }
                .httpBasic()
                .and()
                .csrf()
                .disable()
    }

    @Bean
    fun passwordEncoder(): PasswordEncoder {
        return BCryptPasswordEncoder()
    }
}