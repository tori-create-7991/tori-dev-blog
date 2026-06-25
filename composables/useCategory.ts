export const useCategory = () => {
    const mainStore = useStore()

    const moveCategory = (category: string) :void => {
        mainStore.setCategory(category)
        // Encode the tag for the URL
        const encodedCategory = encodeURIComponent(category)

        console.log("moveCategory", category)
        console.log("encodedCategory", encodedCategory)

        navigateTo(`/category/${encodedCategory}`)
    }

    return {
        moveCategory,
    }
}
