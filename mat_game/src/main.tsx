import React from "react";
import ReactDOM from "react-dom/client";
import { Calculator, CheckCircle2, CircleHelp, RefreshCw, XCircle } from "lucide-react";
import questionsData from "./questions.json";
import "./styles.css";

type Level = "basic" | "medium" | "advanced";
type ResultState = "correct" | "wrong" | "timeout" | null;

type Question = {
  id: number;
  level: Level;
  expression: string;
  prompt: string;
  options: number[];
  answer: number;
  solution: string;
};

const levelLabels: Record<Level, string> = {
  basic: "Basit",
  medium: "Orta",
  advanced: "Ileri",
};

const questions = questionsData as Question[];
const TIME_LIMIT_SECONDS = 10;

function playTone(kind: "success" | "error") {
  const AudioContextClass = window.AudioContext || window.webkitAudioContext;
  if (!AudioContextClass) return;

  const audioContext = new AudioContextClass();
  const masterGain = audioContext.createGain();
  masterGain.gain.setValueAtTime(0.0001, audioContext.currentTime);
  masterGain.connect(audioContext.destination);

  const notes = kind === "success" ? [523.25, 659.25, 783.99] : [220, 164.81];
  notes.forEach((frequency, index) => {
    const start = audioContext.currentTime + index * 0.12;
    const oscillator = audioContext.createOscillator();
    const gain = audioContext.createGain();

    oscillator.type = kind === "success" ? "triangle" : "sawtooth";
    oscillator.frequency.setValueAtTime(frequency, start);
    gain.gain.setValueAtTime(0.0001, start);
    gain.gain.exponentialRampToValueAtTime(kind === "success" ? 0.18 : 0.12, start + 0.02);
    gain.gain.exponentialRampToValueAtTime(0.0001, start + 0.22);

    oscillator.connect(gain);
    gain.connect(masterGain);
    oscillator.start(start);
    oscillator.stop(start + 0.24);
  });

  masterGain.gain.exponentialRampToValueAtTime(0.55, audioContext.currentTime + 0.02);
  masterGain.gain.exponentialRampToValueAtTime(0.0001, audioContext.currentTime + 0.65);
}

function getRandomQuestion(level: Level, previousId?: number) {
  const pool = questions.filter((question) => question.level === level);
  const candidates = pool.length > 1 ? pool.filter((question) => question.id !== previousId) : pool;
  return candidates[Math.floor(Math.random() * candidates.length)];
}

function App() {
  const [isRulesOpen, setIsRulesOpen] = React.useState(true);
  const [level, setLevel] = React.useState<Level>("basic");
  const [currentQuestion, setCurrentQuestion] = React.useState<Question | null>(null);
  const [selectedAnswer, setSelectedAnswer] = React.useState<number | null>(null);
  const [result, setResult] = React.useState<ResultState>(null);
  const [timeLeft, setTimeLeft] = React.useState(TIME_LIMIT_SECONDS);
  const [score, setScore] = React.useState({ correct: 0, wrong: 0 });

  const startQuestion = React.useCallback(
    (selectedLevel = level) => {
      setCurrentQuestion((previous) => getRandomQuestion(selectedLevel, previous?.id));
      setSelectedAnswer(null);
      setResult(null);
      setTimeLeft(TIME_LIMIT_SECONDS);
    },
    [level],
  );

  React.useEffect(() => {
    if (!currentQuestion || result !== null) return;

    if (timeLeft === 0) {
      setResult("timeout");
      setScore((previous) => ({
        correct: previous.correct,
        wrong: previous.wrong + 1,
      }));
      playTone("error");
      return;
    }

    const timerId = window.setTimeout(() => {
      setTimeLeft((previous) => previous - 1);
    }, 1000);

    return () => window.clearTimeout(timerId);
  }, [currentQuestion, result, timeLeft]);

  function handleLevelChange(nextLevel: Level) {
    setLevel(nextLevel);
    startQuestion(nextLevel);
  }

  function handleAnswer(answer: number) {
    if (!currentQuestion || selectedAnswer !== null) return;

    const isCorrect = answer === currentQuestion.answer;
    setSelectedAnswer(answer);
    setResult(isCorrect ? "correct" : "wrong");
    setScore((previous) => ({
      correct: previous.correct + (isCorrect ? 1 : 0),
      wrong: previous.wrong + (isCorrect ? 0 : 1),
    }));
    playTone(isCorrect ? "success" : "error");
  }

  const feedbackTitle =
    result === "correct"
      ? "Dogru cevap!"
      : result === "wrong"
        ? "Yanlis cevap"
        : result === "timeout"
          ? "Sure bitti"
          : "Cevabini sec";

  return (
    <main className={`app ${result ?? "idle"}`}>
      {isRulesOpen && (
        <div className="modal-backdrop" role="dialog" aria-modal="true" aria-labelledby="rules-title">
          <section className="rules-modal">
            <div className="rules-icon" aria-hidden="true">
              <CircleHelp size={34} />
            </div>
            <h1 id="rules-title">Oyunun kurallari</h1>
            <p>
              Bu oyun hesap makinesi gorunumunde temel matematik pratigi yaptirir. Basit, orta veya
              ileri seviyeyi secip Basla dugmesine bastiginda ekrana JSON dosyasindan rastgele bir soru
              gelir.
            </p>
            <p>
              Her soruda dort cevap vardir. Dogru cevaba tiklarsan yesil geri bildirim ve alkis tonu
              duyarsin; yanlis cevaba tiklarsan kirmizi geri bildirim ve hata tonu duyarsin. Her iki
              durumda da dogru cevap ve cozum adimlari ekranda gosterilir.
            </p>
            <p>
              Basit seviye dort islem agirliklidir. Orta seviyede yuzde, kok ve uslu sayilar devreye
              girer. Ileri seviye ise islemleri birlestiren daha dikkat isteyen sorulardan olusur.
            </p>
            <button className="primary-button" type="button" onClick={() => setIsRulesOpen(false)}>
              Oyuna gec
            </button>
          </section>
        </div>
      )}

      <section className="game-shell">
        <div className="screen">
          <div>
            <span className="eyebrow">Matematik hesap makinesi</span>
            <h1>Dort islem, kok, us ve yuzde oyunu</h1>
          </div>
          <div className="scoreboard" aria-label="Skor">
            <span>Dogru: {score.correct}</span>
            <span>Yanlis: {score.wrong}</span>
          </div>
        </div>

        <div className="calculator">
          <aside className="control-panel" aria-label="Seviye secimi">
            <div className="brand-row">
              <Calculator size={24} />
              <strong>MAT-Calc</strong>
            </div>
            <div className="level-tabs">
              {(Object.keys(levelLabels) as Level[]).map((item) => (
                <button
                  className={item === level ? "active" : ""}
                  type="button"
                  key={item}
                  onClick={() => handleLevelChange(item)}
                >
                  {levelLabels[item]}
                </button>
              ))}
            </div>
            <button className="start-button" type="button" onClick={() => startQuestion()}>
              <RefreshCw size={18} />
              Basla
            </button>
          </aside>

          <section className="question-panel" aria-live="polite">
            {currentQuestion ? (
              <>
                <div className="display">
                  <div className="display-meta">
                    <span>{levelLabels[currentQuestion.level]} seviye</span>
                    <span className={timeLeft <= 3 && result === null ? "timer urgent" : "timer"}>
                      {timeLeft} sn
                    </span>
                  </div>
                  <strong>{currentQuestion.expression}</strong>
                  <p>{currentQuestion.prompt}</p>
                </div>

                <div className="answers">
                  {currentQuestion.options.map((option) => {
                    const isSelected = option === selectedAnswer;
                    const isAnswer = option === currentQuestion.answer;
                    const shouldRevealAnswer = result !== null;
                    const stateClass =
                      !shouldRevealAnswer
                        ? ""
                        : isAnswer
                          ? "answer-correct"
                          : isSelected
                            ? "answer-wrong"
                            : "answer-muted";

                    return (
                      <button
                        key={option}
                        className={stateClass}
                        type="button"
                        disabled={result !== null}
                        onClick={() => handleAnswer(option)}
                      >
                        {option}
                      </button>
                    );
                  })}
                </div>

                <div className={`feedback ${result ?? ""}`}>
                  {result === "correct" ? (
                    <CheckCircle2 size={24} />
                  ) : result === "wrong" || result === "timeout" ? (
                    <XCircle size={24} />
                  ) : null}
                  <div>
                    <strong>{feedbackTitle}</strong>
                    {result !== null ? (
                      <p>
                        Dogru cevap: <b>{currentQuestion.answer}</b>. {currentQuestion.solution}
                      </p>
                    ) : (
                      <p>Bir sikka tikladiginda cozum burada acilir.</p>
                    )}
                    {result !== null && (
                      <button className="next-button" type="button" onClick={() => startQuestion()}>
                        <RefreshCw size={17} />
                        Yeni soru
                      </button>
                    )}
                  </div>
                </div>
              </>
            ) : (
              <div className="empty-state">
                <Calculator size={46} />
                <strong>Hazir oldugunda Basla</strong>
                <p>Secili seviyeden yeni bir soru getirmek icin Basla dugmesine bas.</p>
              </div>
            )}
          </section>
        </div>
      </section>
    </main>
  );
}

declare global {
  interface Window {
    webkitAudioContext?: typeof AudioContext;
  }
}

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
