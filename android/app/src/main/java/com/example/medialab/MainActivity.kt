package com.example.medialab

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.medialab.viewmodel.FeedItemsViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            HomeView()
        }
    }
}

@Composable
fun HomeView(modifier: Modifier = Modifier) {
    ListView()
}

@Composable
fun ListView(modifier: Modifier = Modifier, viewModel: FeedItemsViewModel = viewModel()
) {
    LaunchedEffect(Unit) {
        viewModel.fetchItems()
    }

    LazyColumn(modifier = modifier) {
        items(viewModel.items) { index ->
            Text(text = "Item $index")
        }
    }
}
