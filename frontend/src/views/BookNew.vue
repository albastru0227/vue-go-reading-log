<script setup>
//登録に成功したときに一覧ページに戻るためのモジュール
import { useRouter } from 'vue-router'
import { ref } from 'vue'
import { API_BASE } from '@/api'

//ルーターの設定
const router = useRouter()

//フォームの入力項目の変数
const author = ref('')
const title = ref('')
const note = ref('')

//登録ボタンがクリックされたときの処理を決める関数
const addBook = async () => {
  //goのサーバーに入力された文字を送る
  await fetch(`${API_BASE}/books`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title: title.value, author: author.value, note: note.value}),
  })

  //登録が成功した際、一覧ページに戻るようにする
  router.push('/')
}
</script>

<template>
  <div class="container">
    <h1 class="my-4">新規登録</h1>
    <div class="card">
      <div class="card-body">
        <h2 class="h5 mb-3">新しい本を登録</h2>

        <label class="form-label">タイトル</label>
        <!-- v-model: inputとjavascriptの変数の双方を結びつける-->
        <!-- placeholder: 空欄の時に薄く表示させる文字-->
        <input v-model="title" placeholder="タイトル" class="form-control mb-2" />

        <label class="form-label">著者</label>
        <input v-model="author" placeholder="著者" class="form-control mb-2"/>

        <label class="form-label">メモ</label>
        <textarea v-model="note" placeholder="メモ" class="form-control mb-2"></textarea>

        <!-- @click: クリックされたときに対応する関数を実行する-->
        <button @click="addBook" class="btn btn-primary btn">登録</button>    
      </div>
    </div>  
    <router-link to="/" class="btn btn-primary my-3">一覧ページに戻る</router-link>
  </div>
</template>

<style scoped>

</style>
