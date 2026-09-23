<script setup>
import { useRoute, useRouter } from 'vue-router'; 
import { ref, onMounted } from 'vue';
import { API_BASE } from '@/api';

const route = useRoute() //idを取得するためのモジュール
const router = useRouter()

//idを取得する
const id = route.params.id

//既存の情報を格納する変数を定義する
const book = ref({})

//ページ読み込みの最初に行う処理
onMounted(async () => {
    const res = await fetch(`${API_BASE}/books/${id}`)
    const data = await res.json()
    book.value = data
})

//更新処理を行い、一覧ページに戻る
const updateBook = async () => {
    await fetch(`${API_BASE}/books/${id}`, {
        method: "PUT",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify(book.value)
    })
    router.push('/')
}

</script>

<template>
    <div class="container">
        <h1 class="my-4">更新ページ</h1>
        
        <label class="form-label">タイトル</label>
        <input v-model="book.title" class="form-control mb-2" />

        <label class="form-label">著者</label>
        <input v-model="book.author" class="form-control mb-2" />

        <label class="form-label">ステータス</label>
        <select v-model="book.status" class="form-select mb-2">
            <option value="未読">未読</option>
            <option value="読書中">読書中</option>
            <option value="読了">読了</option>
        </select>

        <label class="form-label">評価</label>
        <select v-model="book.rating" class="form-select mb-2">
            <option :value="null"></option>
            <option :value="1">1</option>
            <option :value="2">2</option>
            <option :value="3">3</option>
            <option :value="4">4</option>
            <option :value="5">5</option>
        </select>

        <label class="form-label">メモ</label>
        <textarea v-model="book.note" class="form-control mb-2"></textarea>

        <button @click="updateBook" class="btn btn-primary">保存</button>
    </div>
</template>