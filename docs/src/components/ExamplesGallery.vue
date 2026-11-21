<script setup lang="ts">
// The example gallery as cards, in reading order: a thumbnail of the solution, the title,
// the story, what the example introduces, and its facts. Data in examples.ts. A thumbnail
// is saved by its example page at build time; when it is missing (a page built in draft
// mode), the card shows no image.
import { reactive } from 'vue'
import { withBase } from 'vitepress'
import { examples } from './examples'

const missing = reactive<Record<string, boolean>>({})
</script>

<template>
  <div class="oc-gallery">
    <a
      v-for="(ex, i) in examples"
      :key="ex.id"
      class="oc-card"
      :href="withBase(`/examples/${ex.id}`)"
    >
      <div v-if="!missing[ex.id]" class="oc-card-thumb">
        <img
          :src="withBase(`/gallery/${ex.id}.svg`)"
          :alt="`The solution of ${ex.title}`"
          loading="lazy"
          @error="missing[ex.id] = true"
        />
      </div>
      <div class="oc-card-body">
        <div class="oc-card-title">{{ i + 1 }}. {{ ex.title }}</div>
        <p class="oc-card-story">{{ ex.story }}</p>
        <p class="oc-card-introduces"><strong>Introduces:</strong> {{ ex.introduces }}</p>
        <div class="oc-facts">
          <span v-for="fact in ex.facts" :key="fact" class="oc-fact">{{ fact }}</span>
        </div>
      </div>
    </a>
  </div>
</template>
