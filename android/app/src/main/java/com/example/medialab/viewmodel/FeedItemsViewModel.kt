package com.example.medialab.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.medialab.model.FeedItem
import com.example.medialab.network.FeedRetrofitClient
import kotlinx.coroutines.launch

class FeedItemsViewModel: ViewModel() {
    var items by mutableStateOf<List<FeedItem>>(emptyList())
        private set

   fun fetchItems() {
    viewModelScope.launch {
        try {
            items = FeedRetrofitClient.api.getItems()
        } catch (e: Exception) {
            print("Error: ${e.message}")
        }
    }
   } 
}
