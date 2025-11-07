export default {
  mounted() {
    const input = this.el.querySelector('input[type="text"]');
    
    if (input) {
      this.handleKeyPress = this.handleKeyPress.bind(this);
      document.addEventListener('keydown', this.handleKeyPress);
    }
  },

  destroyed() {
    if (this.handleKeyPress) {
      document.removeEventListener('keydown', this.handleKeyPress);
    }
  },

  handleKeyPress(e) {
    const isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0;
    const modifierKey = isMac ? e.metaKey : e.ctrlKey;
    
    const isInputField = document.activeElement.tagName === 'INPUT' || 
                         document.activeElement.tagName === 'TEXTAREA';
    
    if ((e.key === '/' && !isInputField) || 
        (e.key === 'k' && modifierKey)) {
      e.preventDefault();
      const input = document.getElementById('model-search-input');
      if (input) {
        input.focus();
        input.select();
      }
    }
  }
};
