package com.example.medialab


import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items

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
fun ListView(modifier: Modifier = Modifier) {
    LazyColumn(modifier = modifier) {
        items(10) { index ->
            Text(text = "Item $index")
        }
    }
}
