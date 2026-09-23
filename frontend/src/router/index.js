//vue-routerから必要なモジュールをインポートして、各ページもインポートする
import {createRouter, createWebHistory } from 'vue-router'
import BookList from "@/views/BookList.vue"
import BookNew from '@/views/BookNew.vue'
import BookEdit from '@/views/BookEdit.vue'

//パスと表示させるファイルを紐づける
const routes = [
    { path: '/', component: BookList },
    { path: '/new', component: BookNew },
    { path: '/edit/:id', component: BookEdit },
]

//ルーターの作成
const router = createRouter({
    history: createWebHistory(), //きれいなURLを作成するために指定する
    routes,
})

//routerを他ファイルでも使えるようにする
export default router
