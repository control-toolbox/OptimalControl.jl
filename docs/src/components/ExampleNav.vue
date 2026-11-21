<script setup lang="ts">
// Previous example · gallery · next example, at the end of each example page. The examples
// are not listed in the sidebar (the gallery is), so this keeps their reading order (data in
// examples.ts).
import { computed } from 'vue'
import { withBase } from 'vitepress'
import { examples } from './examples'

const props = defineProps<{ id: string }>()
const index = computed(() => examples.findIndex((ex) => ex.id === props.id))
const previous = computed(() => (index.value > 0 ? examples[index.value - 1] : undefined))
const next = computed(() =>
  index.value >= 0 && index.value < examples.length - 1 ? examples[index.value + 1] : undefined,
)
</script>

<template>
  <nav v-if="index >= 0" class="oc-example-nav" aria-label="Examples">
    <a v-if="previous" class="oc-example-nav-link" :href="withBase(`/examples/${previous.id}`)">
      <span class="oc-example-nav-label">Previous example</span>
      <span class="oc-example-nav-title">{{ previous.title }}</span>
    </a>
    <span v-else />
    <a class="oc-example-nav-link oc-example-nav-gallery" :href="withBase('/examples/gallery')">
      <span class="oc-example-nav-label">All examples</span>
      <span class="oc-example-nav-title">Gallery</span>
    </a>
    <a v-if="next" class="oc-example-nav-link oc-example-nav-next" :href="withBase(`/examples/${next.id}`)">
      <span class="oc-example-nav-label">Next example</span>
      <span class="oc-example-nav-title">{{ next.title }}</span>
    </a>
    <span v-else />
  </nav>
</template>
