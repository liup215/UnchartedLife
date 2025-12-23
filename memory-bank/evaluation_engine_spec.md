# Offline Evaluation Engine - Technical Specification

## Overview

The Offline Evaluation Engine is the **highest priority** feature for Phase 2. It enables the game to evaluate mathematical expressions and open-ended answers without requiring an internet connection, using a local Python + SymPy service.

---

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                         Godot Game                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         EvaluationClient.gd (Autoload)               │  │
│  │  - HTTP request management                           │  │
│  │  - Request queuing                                   │  │
│  │  - Response parsing                                  │  │
│  │  - Fallback logic                                    │  │
│  └────────────────┬─────────────────────────────────────┘  │
│                   │ HTTP (localhost:5000)                   │
└───────────────────┼─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│              Python Evaluation Service                      │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           Flask/FastAPI Server                       │  │
│  │  - REST API endpoints                                │  │
│  │  - Request validation                                │  │
│  │  - Response formatting                               │  │
│  └────────────────┬─────────────────────────────────────┘  │
│                   │                                          │
│  ┌────────────────▼─────────────────────────────────────┐  │
│  │         SymPy Evaluator Module                       │  │
│  │  - Equation solving                                  │  │
│  │  - Expression simplification                         │  │
│  │  - Symbolic comparison                               │  │
│  │  - LaTeX parsing (optional)                          │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## API Specification

### Endpoint: `/evaluate`

**Method:** POST

**Request Body:**
```json
{
  "question_id": "q_algebra_001",
  "question_type": "equation_solve",
  "question_text": "Solve for x: 2x + 5 = 13",
  "student_answer": "x=4",
  "expected_answer": "x=4",
  "evaluation_params": {
    "tolerance": 0.001,
    "accept_equivalent": true,
    "allow_multiple_forms": true
  }
}
```

**Response Body (Success):**
```json
{
  "status": "success",
  "correct": true,
  "confidence": 1.0,
  "normalized_answer": "x = 4",
  "feedback": "Correct! Well done.",
  "evaluation_method": "sympy_equation_solve",
  "processing_time_ms": 15
}
```

**Response Body (Incorrect):**
```json
{
  "status": "success",
  "correct": false,
  "confidence": 1.0,
  "normalized_answer": "x = 2",
  "expected_normalized": "x = 4",
  "feedback": "Incorrect. Check your arithmetic.",
  "hint": "Subtract 5 from both sides first.",
  "evaluation_method": "sympy_equation_solve",
  "processing_time_ms": 12
}
```

**Response Body (Error):**
```json
{
  "status": "error",
  "error_type": "parse_error",
  "message": "Unable to parse student answer",
  "fallback_evaluation": {
    "correct": false,
    "method": "string_match"
  }
}
```

---

## Evaluation Methods

### 1. Equation Solving (equation_solve)

**Use Case:** "Solve for x: 2x + 5 = 13"

**Algorithm:**
```python
def evaluate_equation_solve(question_text, student_answer, expected_answer):
    # 1. Parse equation from question
    equation = parse_equation("2x + 5 = 13")
    
    # 2. Solve symbolically
    solution = sympy.solve(equation, x)
    
    # 3. Parse student answer
    student_value = parse_answer(student_answer)
    
    # 4. Compare
    return student_value in solution or sympy.simplify(student_value - solution[0]) == 0
```

**Accepted Answer Formats:**
- `x=4`
- `x = 4`
- `4`
- `x equals 4`
- `x is 4`

---

### 2. Expression Simplification (expression_simplify)

**Use Case:** "Simplify: 2x + 3x"

**Algorithm:**
```python
def evaluate_expression_simplify(expression, student_answer):
    # 1. Simplify the reference expression
    expected = sympy.simplify(expression)
    
    # 2. Simplify student answer
    student = sympy.simplify(student_answer)
    
    # 3. Check symbolic equivalence
    return sympy.simplify(expected - student) == 0
```

**Accepted Answer Formats:**
- `5x`
- `5*x`
- `x*5`
- `x + x + x + x + x`

---

### 3. Numeric Evaluation (numeric_eval)

**Use Case:** "Calculate: 12 × 8"

**Algorithm:**
```python
def evaluate_numeric(expression, student_answer, tolerance=0.001):
    # 1. Evaluate expected
    expected = float(sympy.sympify(expression).evalf())
    
    # 2. Parse student answer
    student = float(parse_numeric(student_answer))
    
    # 3. Compare with tolerance
    return abs(expected - student) < tolerance
```

**Tolerance Settings:**
- Integer problems: 0 (exact match)
- Decimal problems: 0.001
- Fractions: symbolic comparison

---

### 4. Expression Equivalence (expression_equiv)

**Use Case:** "Is 2(x+3) equivalent to 2x+6?"

**Algorithm:**
```python
def evaluate_equivalence(expr1, expr2):
    # Expand and simplify both
    diff = sympy.expand(expr1) - sympy.expand(expr2)
    return sympy.simplify(diff) == 0
```

---

### 5. Fraction Evaluation (fraction_eval)

**Use Case:** "Simplify: 6/8"

**Algorithm:**
```python
def evaluate_fraction(student_answer, expected):
    # Parse as fractions
    student_frac = sympy.Rational(student_answer)
    expected_frac = sympy.Rational(expected)
    
    # Compare
    return student_frac == expected_frac
```

**Accepted Answer Formats:**
- `3/4`
- `0.75`
- `75/100`

---

## Implementation Details

### Python Service Structure

```
evaluation_service/
├── app.py                      # Main Flask/FastAPI application
├── evaluators/
│   ├── __init__.py
│   ├── base_evaluator.py      # Abstract base class
│   ├── equation_evaluator.py
│   ├── expression_evaluator.py
│   ├── numeric_evaluator.py
│   └── fraction_evaluator.py
├── parsers/
│   ├── __init__.py
│   ├── answer_parser.py       # Parse student input
│   └── question_parser.py     # Extract expressions from questions
├── config.py                   # Configuration
├── requirements.txt
└── tests/
    ├── test_evaluators.py
    └── test_parsers.py
```

### Key Python Dependencies

```txt
# requirements.txt
flask==3.0.0           # Web framework
sympy==1.12            # Symbolic mathematics
numpy==1.26.0          # Numerical operations
flask-cors==4.0.0      # CORS support for local requests
gunicorn==21.2.0       # Production server (optional)
pytest==7.4.0          # Testing
```

### Minimal Flask Implementation

```python
# app.py
from flask import Flask, request, jsonify
from evaluators.equation_evaluator import EquationEvaluator
from evaluators.expression_evaluator import ExpressionEvaluator
from evaluators.numeric_evaluator import NumericEvaluator
import time

app = Flask(__name__)

evaluators = {
    'equation_solve': EquationEvaluator(),
    'expression_simplify': ExpressionEvaluator(),
    'numeric_eval': NumericEvaluator(),
}

@app.route('/evaluate', methods=['POST'])
def evaluate():
    start_time = time.time()
    
    try:
        data = request.json
        question_type = data['question_type']
        
        if question_type not in evaluators:
            return jsonify({
                'status': 'error',
                'error_type': 'unsupported_type',
                'message': f'Question type {question_type} not supported'
            }), 400
        
        evaluator = evaluators[question_type]
        result = evaluator.evaluate(data)
        
        result['processing_time_ms'] = int((time.time() - start_time) * 1000)
        result['status'] = 'success'
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({
            'status': 'error',
            'error_type': 'evaluation_error',
            'message': str(e)
        }), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'version': '1.0.0'})

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=False)
```

---

## Godot Integration

### EvaluationClient.gd (Autoload)

```gdscript
# systems/evaluation_service/evaluation_client.gd
extends Node

signal evaluation_complete(result: Dictionary)
signal evaluation_error(error: String)

const SERVICE_URL := "http://127.0.0.1:5000"
const TIMEOUT_SECONDS := 5.0

var _http_client: HTTPRequest
var _service_available: bool = false
var _pending_requests: Array[Dictionary] = []

func _ready() -> void:
	_http_client = HTTPRequest.new()
	add_child(_http_client)
	_http_client.timeout = TIMEOUT_SECONDS
	_http_client.request_completed.connect(_on_request_completed)
	
	# Check service availability
	_check_service_health()

func _check_service_health() -> void:
	var error = _http_client.request(SERVICE_URL + "/health")
	if error != OK:
		push_warning("EvaluationClient: Failed to connect to evaluation service")
		_service_available = false
	else:
		await _http_client.request_completed
		_service_available = true

func evaluate_answer(
	question_id: String,
	question_type: String,
	question_text: String,
	student_answer: String,
	expected_answer: String,
	params: Dictionary = {}
) -> void:
	
	var request_data := {
		"question_id": question_id,
		"question_type": question_type,
		"question_text": question_text,
		"student_answer": student_answer,
		"expected_answer": expected_answer,
		"evaluation_params": params
	}
	
	if not _service_available:
		push_warning("EvaluationClient: Service unavailable, using fallback")
		_fallback_evaluation(request_data)
		return
	
	var json_string := JSON.stringify(request_data)
	var headers := ["Content-Type: application/json"]
	
	var error := _http_client.request(
		SERVICE_URL + "/evaluate",
		headers,
		HTTPClient.METHOD_POST,
		json_string
	)
	
	if error != OK:
		push_error("EvaluationClient: HTTP request failed")
		_fallback_evaluation(request_data)

func _on_request_completed(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_error("EvaluationClient: Request failed")
		evaluation_error.emit("Request failed")
		return
	
	var json := JSON.new()
	var parse_result := json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		push_error("EvaluationClient: Failed to parse response")
		evaluation_error.emit("Parse error")
		return
	
	var response_data: Dictionary = json.data
	evaluation_complete.emit(response_data)

func _fallback_evaluation(request_data: Dictionary) -> void:
	# Simple string matching fallback
	var student := request_data["student_answer"].strip_edges().to_lower()
	var expected := request_data["expected_answer"].strip_edges().to_lower()
	
	var correct := student == expected
	
	var result := {
		"status": "success",
		"correct": correct,
		"confidence": 0.5,
		"normalized_answer": student,
		"feedback": "Correct!" if correct else "Incorrect.",
		"evaluation_method": "fallback_string_match",
		"processing_time_ms": 0
	}
	
	evaluation_complete.emit(result)
```

---

## Usage Example

### In BioBlitzManager or QuizSystem

```gdscript
func _on_student_answer_submitted(answer: String) -> void:
	var question := current_question as QuestionDataV2
	
	# Show loading indicator
	quiz_ui.show_loading()
	
	# Request evaluation
	EvaluationClient.evaluate_answer(
		question.id,
		_get_question_type_string(question.question_type),
		question.question_text,
		answer,
		question.correct_answers[0],
		{
			"tolerance": question.tolerance,
			"accept_equivalent": true
		}
	)
	
	# Wait for result
	var result = await EvaluationClient.evaluation_complete
	
	# Hide loading
	quiz_ui.hide_loading()
	
	# Handle result
	if result["correct"]:
		_handle_correct_answer(result)
	else:
		_handle_incorrect_answer(result)

func _get_question_type_string(type: QuestionDataV2.QuestionType) -> String:
	match type:
		QuestionDataV2.QuestionType.EQUATION_SOLVE:
			return "equation_solve"
		QuestionDataV2.QuestionType.EXPRESSION_SIMPLIFY:
			return "expression_simplify"
		QuestionDataV2.QuestionType.NUMERIC_EVAL:
			return "numeric_eval"
		_:
			return "string_match"
```

---

## Deployment Strategy

### Development Mode
```bash
# Start Python service manually
cd evaluation_service
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py
```

### Production Mode (Embedded)

1. **Bundle Python Runtime**
   - Use PyInstaller to create standalone executable
   - Include in game's `evaluation_service/` directory
   - Auto-start on game launch

2. **Godot Launch Script**
```gdscript
# systems/evaluation_service/service_launcher.gd
extends Node

var _service_process: int = -1

func _ready() -> void:
	_launch_service()

func _launch_service() -> void:
	var service_path := _get_service_executable_path()
	
	if not FileAccess.file_exists(service_path):
		push_error("Evaluation service not found!")
		return
	
	var output := []
	_service_process = OS.create_process(service_path, [], false)
	
	if _service_process == -1:
		push_error("Failed to launch evaluation service")
	else:
		print("Evaluation service started (PID: %d)" % _service_process)
	
	# Wait for service to be ready
	await get_tree().create_timer(1.0).timeout

func _exit_tree() -> void:
	if _service_process != -1:
		OS.kill(_service_process)

func _get_service_executable_path() -> String:
	match OS.get_name():
		"Windows":
			return "res://evaluation_service/evaluator.exe"
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			return "res://evaluation_service/evaluator"
		"macOS":
			return "res://evaluation_service/evaluator"
		_:
			return ""
```

---

## Testing Strategy

### Unit Tests (Python)

```python
# tests/test_evaluators.py
import pytest
from evaluators.equation_evaluator import EquationEvaluator

def test_simple_equation():
    evaluator = EquationEvaluator()
    result = evaluator.evaluate({
        'question_text': 'Solve for x: 2x + 5 = 13',
        'student_answer': 'x=4',
        'expected_answer': 'x=4'
    })
    assert result['correct'] == True

def test_equation_multiple_formats():
    evaluator = EquationEvaluator()
    
    test_cases = ['x=4', '4', 'x = 4', 'x equals 4']
    
    for answer in test_cases:
        result = evaluator.evaluate({
            'question_text': 'Solve for x: 2x + 5 = 13',
            'student_answer': answer,
            'expected_answer': 'x=4'
        })
        assert result['correct'] == True, f"Failed for: {answer}"
```

### Integration Tests (Godot)

```gdscript
# tests/test_evaluation_integration.gd
extends Node

func test_evaluation_service() -> void:
	# Test service availability
	assert(EvaluationClient._service_available, "Service not available")
	
	# Test simple evaluation
	EvaluationClient.evaluate_answer(
		"test_001",
		"equation_solve",
		"Solve for x: 2x = 8",
		"x=4",
		"x=4"
	)
	
	var result = await EvaluationClient.evaluation_complete
	assert(result["correct"] == true, "Evaluation failed")
	assert(result["confidence"] > 0.9, "Low confidence")
	
	print("✓ Evaluation service test passed")
```

---

## Performance Requirements

### Latency Targets
- **Target:** <50ms per evaluation
- **Acceptable:** <100ms per evaluation
- **Maximum:** <500ms per evaluation

### Optimization Strategies
1. **Caching:** Cache frequently evaluated expressions
2. **Connection Pooling:** Reuse HTTP connections
3. **Lazy Loading:** Load SymPy modules on-demand
4. **Result Memoization:** Cache identical questions

### Benchmark Results (Expected)
```
Simple numeric: ~5ms
Equation solving: ~15ms
Expression simplification: ~25ms
Complex symbolic: ~50ms
```

---

## Security Considerations

### Input Validation
```python
def validate_input(data):
    # Prevent code injection
    if any(dangerous in data['student_answer'] for dangerous in ['__', 'eval', 'exec', 'import']):
        raise ValueError("Invalid input detected")
    
    # Limit input length
    if len(data['student_answer']) > 500:
        raise ValueError("Input too long")
    
    # Sanitize expressions
    return sanitize_expression(data['student_answer'])
```

### Sandboxing
- Run Python service in restricted environment
- No file system access
- No network access (except localhost)
- Resource limits (CPU, memory)

---

## Fallback Strategies

### Level 1: Simple String Match
```gdscript
func fallback_string_match(student: String, expected: String) -> bool:
	return student.strip_edges().to_lower() == expected.strip_edges().to_lower()
```

### Level 2: Regex Pattern Match
```gdscript
func fallback_pattern_match(student: String, pattern: String) -> bool:
	var regex = RegEx.new()
	regex.compile(pattern)
	return regex.search(student) != null
```

### Level 3: Known Answer Set
```gdscript
func fallback_answer_set(student: String, accepted_answers: Array[String]) -> bool:
	var normalized = student.strip_edges().to_lower()
	for answer in accepted_answers:
		if normalized == answer.to_lower():
			return true
	return false
```

---

## Monitoring & Debugging

### Logging
```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('evaluation_service.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)
```

### Debug Endpoint
```python
@app.route('/debug/evaluate', methods=['POST'])
def debug_evaluate():
    """Returns detailed evaluation steps for debugging"""
    data = request.json
    steps = []
    
    # Log each step
    steps.append({"step": "parse_question", "result": "..."})
    steps.append({"step": "solve_equation", "result": "..."})
    steps.append({"step": "parse_answer", "result": "..."})
    steps.append({"step": "compare", "result": "..."})
    
    return jsonify({"steps": steps})
```

---

## Future Enhancements

### Phase 2.1 (Short-term)
- [ ] Add LaTeX input/output support
- [ ] Implement step-by-step solution generation
- [ ] Add more expression types (trigonometry, logarithms)

### Phase 2.2 (Medium-term)
- [ ] Natural language question parsing
- [ ] Handwriting recognition integration
- [ ] Graph/diagram evaluation

### Phase 2.3 (Long-term)
- [ ] AI-powered answer analysis
- [ ] Partial credit calculation
- [ ] Automated hint generation

---

## Conclusion

The Offline Evaluation Engine is critical for enabling open-ended mathematical questions beyond multiple choice. This specification provides a complete, implementable design that:

1. ✅ Works offline (local Python service)
2. ✅ Handles multiple question types
3. ✅ Provides fast evaluation (<100ms)
4. ✅ Includes fallback mechanisms
5. ✅ Is easily extensible

**Next Step:** Begin implementation with Week 1-2 roadmap from next_phase_prediction.md.
