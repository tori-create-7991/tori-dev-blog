<template>
    <div>
        <Home />
    </div>
</template>

<script setup>
import { siteConfig } from '#shared/siteConfig'

// トップは canonical / OGP をここで出す（title はサイト名のみ）
usePageSeo({
    description: siteConfig.description,
    path: '/',
})
</script>
