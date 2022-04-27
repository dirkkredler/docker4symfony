import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["name"];

    connect() {
        console.log("hey ho");
    }

    play(event) {
        event.preventDefault();
        console.log("oha");
    }

    sayHello() {
        console.log(`Hi ${this.name}`);
    }

    get name() {
        return this.nameTarget.value;
    }
}
