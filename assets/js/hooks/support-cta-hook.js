const STORAGE_KEY = "compare_subs_support_cta_dismissed";

const SupportCta = {
  mounted() {
    this.handleClick = (event) => {
      const trigger = event.target.closest("[data-support-action]");
      if (!trigger) return;

      localStorage.setItem(STORAGE_KEY, "true");
      this.el.classList.add("hidden");
    };

    this.el.addEventListener("click", this.handleClick);
    this.sync();
  },

  updated() {
    this.sync();
  },

  destroyed() {
    if (this.handleClick) {
      this.el.removeEventListener("click", this.handleClick);
    }
  },

  sync() {
    if (localStorage.getItem(STORAGE_KEY) === "true") {
      this.el.classList.add("hidden");
    }
  },
};

export default SupportCta;
