<script setup lang="ts">
// The facts of an example, as a line of chips under its title: the same chips as its card
// in the gallery (data in examples.ts).
import { computed } from 'vue'
import { examples } from './examples'

const props = defineProps<{ id: string }>()
const example = computed(() => examples.find((ex) => ex.id === props.id))
</script>

<template>
  <div v-if="example" class="oc-facts oc-facts--page">
    <span v-for="fact in example.facts" :key="fact" class="oc-fact">{{ fact }}</span>
  </div>
</template>
