export default {
  mounted() {
    this.moveSearch();
    this.handleResize = this.handleResize.bind(this);
    window.addEventListener('resize', this.handleResize);
  },

  updated() {
    this.moveSearch();
  },

  destroyed() {
    window.removeEventListener('resize', this.handleResize);
  },

  handleResize() {
    this.moveSearch();
  },

  moveSearch() {
    const searchForm = document.getElementById('search-form');
    if (!searchForm) return;

    const navContainer = document.getElementById('nav-search-container');
    const mobileContainer = document.getElementById('mobile-search-container');
    
    if (window.innerWidth >= 640) {
      if (navContainer && searchForm.parentElement !== navContainer) {
        navContainer.appendChild(searchForm);
      }
    } else {
      if (mobileContainer && searchForm.parentElement !== mobileContainer) {
        mobileContainer.appendChild(searchForm);
      }
    }
  }
};
