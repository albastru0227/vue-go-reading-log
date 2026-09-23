<script setup>
//ref: リアクティブ変数、onMounted: 画面に表示されたときのみに表示する
import { ref, onMounted } from 'vue';
import { API_BASE } from '@/api';

//読書記録を入れる箱
const book = ref([])

//ステータスによる絞り込みを記録する変数
const filterStatus = ref("")

//データを表示させるための関数
const fetchBooks = async () => {
  //filterStatusの有無で取得するURLを分けて定義する
  const url = filterStatus.value ? `${API_BASE}/books?status=${filterStatus.value}` : `${API_BASE}/books`

  const res = await fetch(url)    // /booksにデータを取得してからresに代入する
  const data = await res.json()                             //代入されたデータをJSON形式に変換してから代入する
  book.value = data                                         //取得したデータをbookに代入する
}

//取得したデータを表示させる
onMounted(() => {
  fetchBooks()
})

//削除ボタンがクリックされたときの処理を決める関数
const deleteBook = async (id) => {
  //goサーバーに削除のリクエストを送る
  await fetch(`${API_BASE}/books/${id}`, {
    method: "DELETE"
  })

  //fetchBooks関数を実行してデータを更新させる
  fetchBooks()
}

//日付表示のための関数
const formatData = (dataString) => {
    return new Date(dataString).toLocaleDateString("ja-JP") 
}

//評価を星で表すための関数
const formatStars = (rating) => {
    if (!rating) {
        return "未評価"
    } else {
        return "★".repeat(rating) + "☆".repeat(5-rating)
    }
}

</script>

<template>
  <div class="container">
    <h1 class="my-4">読書記録一覧</h1>

    <div class="mb-3">
      <button @click="filterStatus = ''; fetchBooks()" :class="filterStatus==='' ? 'btn btn-primary me-2' : 'btn btn-outline-primary me-2'">すべて</button>
      <button @click="filterStatus = '未読'; fetchBooks()" :class="filterStatus==='未読' ? 'btn btn-primary me-2' : 'btn btn-outline-primary me-2'">未読</button>
      <button @click="filterStatus = '読書中'; fetchBooks()" :class="filterStatus==='読書中' ? 'btn btn-primary me-2' : 'btn btn-outline-primary me-2'">読書中</button>
      <button @click="filterStatus = '読了'; fetchBooks()" :class="filterStatus==='読了' ? 'btn btn-primary me-2' : 'btn btn-outline-primary me-2'">読了</button>
    </div>

    <div v-for="b in book" :key="b.id" class="card mb-3">
      <div class="card-body">
        <div class="row">
            <!-- 左カラム：タイトル・著者・ステータス・メモ -->
            <div class="col-8">
                <div class="d-flex align-items-end border-bottom pb-2 mb-3">
                    <h2 class="h4 mb-0 me-3">{{ b.title }}</h2>
                    <span class="text-muted">{{ b.author }}</span>
                </div>
                <div class="mb-3 text-center">{{ b.status }}</div>
                <div class="border rounded p-3" style="min-height: 8rem;">{{ b.note }}</div>
            </div>

            <!-- 右カラム：操作ボタンと補足情報 -->
            <div class="col-4">
                <div class="d-grid gap-2 mb-3">
                    <router-link :to="`/edit/${b.id}`" class="btn btn-outline-primary btn-sm">更新</router-link>
                    <button @click="deleteBook(b.id)" class="btn btn-outline-danger btn-sm">削除</button>
                </div>
                <div class="my-4 text-center">{{ formatStars(b.rating) }}</div>
                <div class="my-4">登録日：{{ formatData(b.createdAt) }}</div>
                <div class="my-4">{{ b.completed ? "読了日：" + formatData(b.completed) : "未読了" }}</div>
            </div>
        </div>
      </div>
    </div>

    <router-link to="/new" class="btn btn-primary mb-3">新しい本を登録</router-link>
  </div>
</template>

<style scoped>

</style>
