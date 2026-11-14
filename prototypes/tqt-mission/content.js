// PROTOTYPE - NOT FOR PRODUCTION · TASK-003
// The story text and the quiz, VI first, then EN. EVERY LINE HERE IS A ⟨placeholder⟩: the content
// owner (game-art-content) writes the sourced story and quiz in TASK-004 and Luan signs them off.
// Nothing here is a historical claim. "Ặ Ỗ Ữ ẫ ợ" is a stacked-diacritic test string (plan review 3).
// Answer icons (drawn in index.html): drum boat lotus flag flag2 flag3 house bamboo child hourglass bed
// orange banana coconut helmet helmet2 helmet3. Per question, the pictures follow game-art-content's
// TASK-004 list (Q1 flags, Q2 child/hourglass/bed, Q3 fruit, Q4 flags, Q5 helmets); the words stay
// ⟨placeholder⟩ until Luan signs off TASK-004.
window.CONTENT = {
  intro: {
    vi: '⟨Giữ chỗ⟩ Câu mở đầu sẽ do nhóm nội dung viết. Ặ Ỗ Ữ ẫ ợ',
    en: '⟨Placeholder⟩ The opening line comes from the content team.',
  },
  beats: [
    { vi: '⟨Giữ chỗ⟩ Lời kể cảnh 1.', en: '⟨Placeholder⟩ Story line for beat 1.' },
    { vi: '⟨Giữ chỗ⟩ Lời kể cảnh 2.', en: '⟨Placeholder⟩ Story line for beat 2.' },
    { vi: '⟨Giữ chỗ⟩ Lời kể cảnh 3.', en: '⟨Placeholder⟩ Story line for beat 3.' },
    { vi: '⟨Giữ chỗ⟩ Lời kể cảnh 4.', en: '⟨Placeholder⟩ Story line for beat 4.' },
  ],
  ending: {
    vi: '⟨Giữ chỗ⟩ Một câu kết nhẹ nhàng.',
    en: '⟨Placeholder⟩ One calm closing line.',
  },
  quiz: [
    {
      q: { vi: '⟨Câu hỏi 1 giữ chỗ⟩ Ặ Ỗ Ữ ẫ ợ?', en: '⟨Placeholder question 1⟩ Which picture is right?' },
      answers: [
        { icon: 'flag', vi: 'Đáp án A ⟨giữ chỗ⟩', en: 'Placeholder answer A, a longer English line' },
        { icon: 'flag2', vi: 'Đáp án B ⟨giữ chỗ⟩', en: 'Placeholder answer B' },
        { icon: 'flag3', vi: 'Đáp án C Ặ Ỗ Ữ ẫ ợ', en: 'Placeholder answer C, longer still to test wrapping' },
      ],
      correct: 0,
    },
    {
      q: { vi: '⟨Câu hỏi 2 giữ chỗ⟩', en: '⟨Placeholder question 2⟩' },
      answers: [
        { icon: 'child', vi: 'Đáp án A ⟨giữ chỗ⟩', en: 'Placeholder answer A' },
        { icon: 'hourglass', vi: 'Đáp án B ⟨giữ chỗ⟩', en: 'Placeholder answer B, a longer English line' },
        { icon: 'bed', vi: 'Đáp án C ⟨giữ chỗ⟩', en: 'Placeholder answer C' },
      ],
      correct: 1,
    },
    {
      q: { vi: '⟨Câu hỏi 3 giữ chỗ⟩', en: '⟨Placeholder question 3⟩' },
      answers: [
        { icon: 'orange', vi: 'Đáp án A ⟨giữ chỗ⟩', en: 'Placeholder answer A' },
        { icon: 'banana', vi: 'Đáp án B ⟨giữ chỗ⟩', en: 'Placeholder answer B' },
        { icon: 'coconut', vi: 'Đáp án C ⟨giữ chỗ⟩', en: 'Placeholder answer C, a longer English line' },
      ],
      correct: 2,
    },
    {
      q: { vi: '⟨Câu hỏi 4 giữ chỗ⟩', en: '⟨Placeholder question 4⟩' },
      answers: [
        { icon: 'flag', vi: 'Đáp án A ⟨giữ chỗ⟩', en: 'Placeholder answer A' },
        { icon: 'flag2', vi: 'Đáp án B ⟨giữ chỗ⟩', en: 'Placeholder answer B' },
        { icon: 'flag3', vi: 'Đáp án C ⟨giữ chỗ⟩', en: 'Placeholder answer C' },
      ],
      correct: 0,
    },
    {
      q: { vi: '⟨Câu hỏi 5 giữ chỗ⟩', en: '⟨Placeholder question 5⟩' },
      answers: [
        { icon: 'helmet', vi: 'Đáp án A ⟨giữ chỗ⟩', en: 'Placeholder answer A' },
        { icon: 'helmet2', vi: 'Đáp án B ⟨giữ chỗ⟩', en: 'Placeholder answer B' },
        { icon: 'helmet3', vi: 'Đáp án C ⟨giữ chỗ⟩', en: 'Placeholder answer C' },
      ],
      correct: 1,
    },
  ],
  nextHero: { vi: '⟨Anh hùng tiếp theo⟩', en: '⟨Next hero⟩' },
};
