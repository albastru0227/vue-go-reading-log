//import './assets/main.css'
import "bootstrap/dist/css/bootstrap.min.css"

import { createApp } from 'vue'
import App from './App.vue'
import router from './router' //routerをインポート

//App.vueファイルを参考にアプリを作成する
//routerを使い、ページの遷移を行う
//index.htmlのid="app"のdivタグに描画する
createApp(App).use(router).mount('#app')
