import css from "../css/app.scss"

import { Socket } from "phoenix"
import LiveSocket from "phoenix_live_view"

let audioGreen = new Audio("https://s3.amazonaws.com/freecodecamp/simonSound1.mp3")
let audioRed = new Audio("https://s3.amazonaws.com/freecodecamp/simonSound2.mp3")
let audioYellow = new Audio("https://s3.amazonaws.com/freecodecamp/simonSound3.mp3")
let audioBlue = new Audio("https://s3.amazonaws.com/freecodecamp/simonSound4.mp3")

let Hooks = {}
Hooks.GreenUpdated = {
  updated() {
    if (this.el.classList.contains("active")) {
      audioGreen.play()
    }
  }
}
Hooks.RedUpdated = {
  updated() {
    if (this.el.classList.contains("active")) {
      audioRed.play()
    }
  }
}
Hooks.YellowUpdated = {
  updated() {
    if (this.el.classList.contains("active")) {
      audioYellow.play()
    }
  }
}
Hooks.BlueUpdated = {
  updated() {
    if (this.el.classList.contains("active")) {
      audioBlue.play()
    }
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, hooks: Hooks });
liveSocket.connect()
