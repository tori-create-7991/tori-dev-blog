export const useTag = () => {
  const mainStore = useStore()

  const moveTag = (tag: string): void => {
    mainStore.setTag(tag)
    // Encode the tag for the URL
    const encodedTag = encodeURIComponent(tag)


    console.log("tag", tag)
    console.log("encodedTag", encodedTag)
    navigateTo(`/tag/${encodedTag}`)
  }

  return {
    moveTag
  }
}
