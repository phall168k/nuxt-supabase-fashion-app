import { defineStore } from 'pinia'

export const useCollapseStore = defineStore('collapseStore', ()=> {
  const isCollapsed = ref<boolean>(false);

  const setCollapse = () => {
    isCollapsed.value = !isCollapsed.value;
  };

  return {
    isCollapsed,
    setCollapse,
  }
})