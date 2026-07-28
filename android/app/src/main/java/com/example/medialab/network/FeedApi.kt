package com.example.medialab.network

import com.example.medialab.model.FeedItem
import retrofit2.http.GET

interface FeedApi {

     @GET("items")
    suspend fun getItems(): List<FeedItem>
}
