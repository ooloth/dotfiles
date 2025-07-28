---
description: Improve type safety and type annotations
---

## Systematic Type Safety Improvement Process

### Phase 0: Planning & Strategy Assessment
**Before adding types, confirm approach:**
- **Have you planned your typing strategy?** If not, start here:
  1. **Quick assessment** - Is this adding a few types or comprehensive typing?
  2. **Consider alternatives**:
     - Gradual typing (add types incrementally, low risk)
     - Full type coverage (comprehensive typing, high effort)
     - Type checking only (add types without runtime changes)
     - Runtime validation (add types + runtime checks)
     - Documentation only (comments instead of types)
  3. **Choose optimal approach** based on:
     - Project maturity and stability
     - Team TypeScript/typing experience
     - Existing type coverage
     - Performance requirements
  4. **Plan rollout strategy** - Which files/modules to type first?

### Phase 1: Type Analysis
1. **Identify missing types** - Functions without return types, untyped parameters
2. **Find type errors** - Runtime type mismatches, unsafe casts
3. **Assess type coverage** - What percentage of code is properly typed?
4. **Review type complexity** - Overly complex types, any types, type assertions

### Phase 2: Domain-Driven Type Strategy
1. **Start with business concepts** - What domain entities and values exist?
2. **Create expressive domain types** - Replace primitives with meaningful types
3. **Model business rules in types** - Make invalid states unrepresentable
4. **Function signatures express intent** - Parameters and returns reflect business operations
5. **Generic types for reusable patterns** - Where code works with multiple domain types

### Phase 3: Expressive Domain Type Implementation

#### 🏢 **Business Domain Types** (Replace primitives with meaning)
**Before:** `string, number, boolean` everywhere
**After:** Domain-specific types that express business concepts

**Examples:**
```typescript
// ❌ Primitive soup - no business meaning
function processPayment(amount: number, userId: string, orderId: string): boolean

// ✅ Expressive domain types
function processPayment(amount: Money, customer: CustomerId, order: OrderId): PaymentResult
```

**Common Domain Type Patterns:**
- **Identifiers**: `UserId`, `OrderId`, `ProductId` instead of `string`
- **Money & Quantities**: `Money`, `Price`, `Quantity` instead of `number`  
- **Status & States**: `OrderStatus`, `UserRole`, `PaymentState` instead of `string`
- **Business Values**: `EmailAddress`, `PhoneNumber`, `PostalCode` instead of `string`
- **Results**: `Result<Success, Error>`, `PaymentResult` instead of throwing exceptions

#### 🛡️ **Type Safety Improvements**
- **Eliminate any types** - Replace with specific domain types
- **Reduce type assertions** - Use type guards and domain validation
- **Strengthen null safety** - Handle undefined/null cases with Maybe/Option types
- **Union types** - Model business states that can be multiple types
- **Discriminated unions** - Type-safe state machines for business workflows
- **Branded types** - Prevent mixing similar primitives (UserId vs OrderId)

### Phase 4: Type Validation
- **Type checking** - Run type checker and fix all errors
- **Runtime validation** - Add runtime checks for external data
- **Type tests** - Verify complex types work as expected
- **Documentation** - Comment complex types and their purpose

### Language-Specific Domain Type Approaches:

**TypeScript:**
```typescript
// Domain-specific branded types
type UserId = string & { readonly __brand: unique symbol };
type Money = { amount: number; currency: string };
type OrderStatus = 'pending' | 'confirmed' | 'shipped' | 'delivered';

// Business logic in types
type PaymentResult = 
  | { success: true; transactionId: string }
  | { success: false; error: PaymentError };
```

**Python:**
```python
# Domain-specific NewTypes and dataclasses
@dataclass(frozen=True)
class Money:
    amount: Decimal
    currency: str

class UserId(str):
    """Branded string type for user identifiers"""
    pass

# Business rules in types
class OrderStatus(Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed" 
    SHIPPED = "shipped"
    DELIVERED = "delivered"
```

**Rust:**
```rust
// Newtypes for domain concepts
#[derive(Debug, Clone, PartialEq)]
pub struct UserId(String);

#[derive(Debug, Clone)]
pub struct Money {
    amount: Decimal,
    currency: Currency,
}

// Business states with enums
#[derive(Debug, PartialEq)]
pub enum PaymentResult {
    Success { transaction_id: String },
    Failed { error: PaymentError },
}
```

**Go:**
```go
// Domain-specific types
type UserId string
type OrderId string
type Money struct {
    Amount   decimal.Decimal
    Currency string
}

// Business states with interfaces
type PaymentResult interface {
    IsSuccess() bool
}

type PaymentSuccess struct {
    TransactionId string
}

type PaymentFailure struct {
    Error error
}
```

### Business-Focused Type Improvements:

#### 🎯 **Make Business Logic Explicit**
- **Replace primitive obsession** - `UserId` instead of `string`
- **Express business constraints** - `PositiveNumber`, `NonEmptyString`
- **Model business workflows** - State machines with discriminated unions
- **Prevent impossible states** - Use types to enforce business rules
- **Self-documenting code** - Types tell the business story

#### 🔧 **Technical Type Improvements**
- **Function signatures** - Clear business operation signatures
- **Null safety** - Optional/Result types for business operations
- **Type guards** - Runtime validation for external data
- **Generic functions** - Reusable patterns for domain types

#### 💰 **Business Value of Domain Types**
- **Fewer bugs** - Can't mix up UserId and OrderId
- **Better communication** - Types match business vocabulary
- **Easier refactoring** - IDE can find all uses of business concepts
- **Self-documenting** - Code explains business rules
- **Onboarding** - New developers understand domain faster

Type improvement target: $ARGUMENTS