package com.mibanco.mbmicroservice;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/") // Define la ruta base opcionalmente
public class HelloController {
    @GetMapping
    public String hello() {
        return "Hola Mibanco";
    }
}
