# Sandbox Options

### Transfer Items On Use

**Description** - Should the toothbrush and toothpaste be transfered from backpacks to the character?<br>
**Type** - Boolean<br>
**Default** - True

---

### Daily Effect

**Description** - The effect type below gets added every day when you haven't brushed your teeth. Uses a formula with the specified parameters below.<br>
**Type** - Boolean<br>
**Default** - True

### Daily Effect Type

**Description** - The type of effect to be added.<br>
**Type** - Enum<br>
**Default** - 1 (Unhappiness)

### Formula Exponent

**Description** - The value to control how fast the unhappiness effect ramps up per day when not brushing teeth.<br>
**Type** - Number (Float)<br>
**Default** - 0.12

### Formula Alternate Exponent

**Description** - The value to control how fast the stress effect ramps up per day when not brushing teeth.<br>
**Type** - Number (Float)<br>
**Default** - 0.12

### Formula Max Value

**Description** - The maximum amount of unhappiness effect that can be applied per day.<br>
**Type** - Number (Integer)<br>
**Default** - 25

### Formula Alternate Max Value

**Description** - The maximum amount of stress effect that can be applied per day.<br>
**Type** - Number (Integer)<br>
**Default** - 25

### Formula Grace Period

**Description** - How long from the 0th brush in days to not apply the daily effects. This can also act like a grace period for world start too as you start with 0 brushes.<br>
**Type** - Number (Integer)<br>
**Default** - 2

---

### Brush Teeth Effect

**Description** - The effect type below gets reduced every time you brush your teeth within (Brush Teeth Max Value) brushes.<br>
**Type** - Boolean<br>
**Default** - True

### Brush Teeth Effect Type

**Description** - The type of effect to be reduced.<br>
**Type** - Enum<br>
**Default** - 1 (Unhappiness)

### Brush Teeth Effect Amount

**Description** - How much to reduce the unhappiness effect.<br>
**Type** - Number (Integer)<br>
**Default** - 10

### Brush Teeth Effect Alternate Amount

**Description** - Brush Teeth Effect Alternate Amount<br>
**Type** - Number (Integer)<br>
**Default** - 10

### Brush Teeth Time

**Description** - How long it takes to brush teeth with toothpaste. Without toothpaste is (time * 2).<br>
**Type** - Number (Integer)<br>
**Default** - 600

### Brush Teeth Max Value

**Description** - How many brushes should give the positive brush effect. For example, going over n brushes will not give any positive effects and would be just for roleplaying purposes.<br>
**Type** - Number (Integer)<br>
**Default** - 2

### Brush Teeth Required Water

**Description** - How much water should be used when brushing teeth.<br>
**Type** - Number (Integer)<br>
**Default** - 1

### Brush Teeth Required Toothpaste

**Description** - How much toothpaste units should be used when brushing teeth.<br>
**Type** - Number (Integer)<br>
**Default** - 1

---

### Good Trait Count

**Description** - The amount of days you need to have brushed your teeth for the full amount for to get the Golden Brusher trait.<br>
**Type** - Number (Integer)<br>
**Default** - 10

### Bad Trait Count

**Description** - The amount of days you need to have not brushed your teeth for to get the Foul Brusher trait.<br>
**Type** - Number (Integer)<br>
**Default** - 7
