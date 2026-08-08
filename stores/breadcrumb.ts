export const useBreadcrumbStore = defineStore('breadcrumbStore', ()=> {
  const breadcrumbs = ref<string[]>([]);
  const pageTitle = ref<string>('');

  const setBreadcrumbs = (e: string[]) => {
   breadcrumbs.value = e;
  };

  const setPageTitle = (e: string) => {
    pageTitle.value = e;
  }

  return {
    breadcrumbs,
    setBreadcrumbs,
    pageTitle,
    setPageTitle,
  }
})