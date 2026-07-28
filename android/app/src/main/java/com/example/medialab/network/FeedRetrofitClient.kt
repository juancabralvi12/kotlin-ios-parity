package com.example.medialab.network

import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

object FeedRetrofitClient {
    private val retrofit = Retrofit.Builder()
        .baseUrl("http://10.0.2.2:8080/v1/items")
        .addConverterFactory(GsonConverterFactory.create())
        .build()

    val api: FeedApi = retrofit.create(FeedApi::class.java)
}
