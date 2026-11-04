<template>
  <div class="quiz">
    <h3 class="quiz-title">
      {{ question }}
    </h3>
    <div v-for="(option, i) in options" :key="i" class="option">
      <button
        @click="handleAnswer(option.isCorrect, i)"
        :class="[
          'option-button',
          selectedOption === i ? 'selected' : '',
          isCorrect ? 'disabled' : ''
        ]"
        :disabled="isCorrect"
      >
        {{ option.text }}
      </button>
    </div>
    <p v-if="feedback" :class="[isCorrect ? 'correct' : 'incorrect']">
      {{ feedback }}
    </p>
    <div v-if="isCorrect" class="explanation">
      <strong>解説:</strong> {{ explanation }}
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  question: {
    type: String,
    required: true
  },
  options: {
    type: Array,
    required: true
  },
  explanation: {
    type: String,
    required: true
  },
  correctMessage: {
    type: String,
    default: "正解です！"
  },
  incorrectMessage: {
    type: String,
    default: "不正解です。もう一度挑戦してください。"
  }
})

const feedback = ref(null)
const isCorrect = ref(false)
const isAnswered = ref(false)
const selectedOption = ref(null)

const handleAnswer = (isCorrectAnswer, idx) => {
  selectedOption.value = idx
  if (isCorrectAnswer) {
    isCorrect.value = true
    isAnswered.value = true
    feedback.value = props.correctMessage
  } else {
    isCorrect.value = false
    feedback.value = props.incorrectMessage
  }
}
</script>

<style scoped>
.quiz {
  margin: 2rem 0;
  padding: 1.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #f8fafc;
}

.quiz-title {
  margin-bottom: 1rem;
  font-size: 1.25rem;
  font-weight: 600;
}

.option {
  margin-bottom: 0.5rem;
}

.option-button {
  width: 100%;
  padding: 0.75rem 1rem;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  background-color: white;
  text-align: left;
  cursor: pointer;
  transition: all 0.2s;
}

.option-button:hover:not(:disabled) {
  background-color: #f1f5f9;
}

.option-button.selected {
  background-color: #e2e8f0;
}

.option-button:disabled {
  cursor: not-allowed;
  opacity: 0.7;
}

.correct {
  color: #10b981;
  margin-top: 1rem;
}

.incorrect {
  color: #ef4444;
  margin-top: 1rem;
}

.explanation {
  margin-top: 1rem;
  padding: 0.75rem;
  background-color: #f1f5f9;
  border-radius: 4px;
  color: #475569;
}
</style>
