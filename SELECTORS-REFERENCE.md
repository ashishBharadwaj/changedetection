# CSS Selector Reference for Indian E-commerce Sites

Quick reference for common CSS selectors when setting up price tracking.

---

## Flipkart

**Product Page Example:** `https://www.flipkart.com/product-name/p/itmXXXXXXX`

### Selectors (as of Feb 2025)

| Element | CSS Selector | Alternative |
|---------|-------------|-------------|
| **Price** | `._30jeq3._16Jk6d` | `.Nx9bqj` |
| **Original Price** | `._3I9_wc` | `.CEmiEU del` |
| **Discount** | `._3Ay6Sb._31Dcoz` | `.VGWI6T` |
| **Product Title** | `.B_NuCI` | `.VU-ZEz` |
| **Availability** | `._16FRp0` | `.row ._2P_LDn` |
| **Rating** | `._3LWZlK` | - |

### Configuration Tips

1. **Enable JavaScript rendering** (Playwright) - REQUIRED
2. **Check interval:** Every 6 hours minimum
3. **User-Agent:** Set to desktop browser
4. **Delay:** 3-5 seconds between checks
5. **Filter:** Use "Trigger on price decrease" or specific price threshold

### Example Watch Setup

```
URL: https://www.flipkart.com/product/p/itmXXXXXXX
JavaScript: ✅ Enabled (Playwright)
Filter: CSS Selector: ._30jeq3._16Jk6d
Trigger: On price decrease
Check interval: 6 hours
```

---

## Myntra

**Product Page Example:** `https://www.myntra.com/tshirts/brand/product-name/12345/buy`

### Selectors (as of Feb 2025)

| Element | CSS Selector | Alternative |
|---------|-------------|-------------|
| **Price** | `.pdp-price strong` | `.pdp-discount-container .pdp-price` |
| **Original Price** | `.pdp-mrp` | `.pdp-discount-container s` |
| **Discount** | `.pdp-discount` | `.pdp-discount-container .pdp-discount` |
| **Product Title** | `.pdp-title` | `.pdp-name` |
| **Brand** | `.pdp-brand` | - |
| **Size Availability** | `.size-buttons-size` | - |

### Configuration Tips

1. **Enable JavaScript rendering** (Playwright) - REQUIRED
2. **Check interval:** Every 4-6 hours
3. **Login required?** No (public product pages)
4. **Dynamic pricing:** Prices may vary by location/time
5. **Filter:** Track discount % or absolute price

### Example Watch Setup

```
URL: https://www.myntra.com/tshirts/brand/product/12345/buy
JavaScript: ✅ Enabled (Playwright)
Filter: CSS Selector: .pdp-price strong
Trigger: On price decrease OR discount increase
Check interval: 6 hours
```

---

## Amazon India

**Product Page Example:** `https://www.amazon.in/dp/B0XXXXXXXXX`

### Selectors (as of Feb 2025)

| Element | CSS Selector | Alternative |
|---------|-------------|-------------|
| **Price (Current)** | `.a-price-whole` | `#priceblock_ourprice` |
| **Price Symbol** | `.a-price-symbol` | - |
| **Strikethrough Price** | `.a-text-price .a-offscreen` | `.priceBlockStrikePriceString` |
| **Product Title** | `#productTitle` | `.product-title-word-break` |
| **Availability** | `#availability span` | - |
| **Discount** | `.savingsPercentage` | `.a-badge-label` |
| **Rating** | `.a-icon-star span` | - |

### Configuration Tips

1. **JavaScript rendering:** Recommended but may work without
2. **Price variation:** Check for "See all buying options" (multiple sellers)
3. **Lightning deals:** Price changes rapidly during sales
4. **Check interval:** Every 3-6 hours
5. **Filter:** Combine price + availability check

### Example Watch Setup

```
URL: https://www.amazon.in/dp/B0XXXXXXXXX
JavaScript: ✅ Enabled (recommended)
Filter: CSS Selector: .a-price-whole
Trigger: On price decrease below ₹X
Check interval: 6 hours
```

---

## General Best Practices

### 1. Enable JavaScript Rendering

**Always enable for:**
- Flipkart ✅
- Myntra ✅
- Amazon (recommended) ✅

**Configuration:**
```
Settings → Use Chrome/Playwright → ✅ Enabled
```

### 2. Set Appropriate Check Intervals

| Frequency | Use Case | Risk |
|-----------|----------|------|
| **1 hour** | Lightning deals, flash sales | High (may trigger rate limiting) |
| **3 hours** | High-priority items | Medium |
| **6 hours** | Normal tracking | Low (recommended) |
| **12 hours** | Low-priority items | Very low |
| **24 hours** | Slow-changing products | Minimal |

### 3. Avoid Rate Limiting

- **Stagger check times** for multiple products
- **Use delays:** 3-5 seconds minimum
- **Rotate User-Agent strings** (advanced)
- **Don't check more than once per hour** per site

### 4. Filter Setup

**Option A: Track Entire Price Block**
```css
CSS Selector: .price-container
```
Good for: Seeing all price changes including original price, discount

**Option B: Track Specific Price Only**
```css
CSS Selector: .current-price-value
```
Good for: Focused alerts, less noise

**Option C: Track with Text Filter**
```
CSS Selector: .price-container
Text Filter: ₹ (₹\d+,?\d*)
```
Good for: Extracting exact numeric value

### 5. Notification Triggers

**Price Decrease:**
```
Trigger: On decrease
```

**Specific Threshold:**
```
Trigger: When price < ₹5000
Filter: Extract price → Compare
```

**Percentage Change:**
```
Trigger: When change > 10%
```

**Any Change:**
```
Trigger: On any change
```

---

## Testing Your Selectors

### Method 1: Browser DevTools

1. **Open product page** in browser
2. **Press F12** (DevTools)
3. **Click "Elements" tab**
4. **Press Ctrl+F** (search)
5. **Paste CSS selector** (e.g., `.pdp-price strong`)
6. **Verify it highlights the price element**

### Method 2: ChangeDetection.io Visual Selector

1. **Add new watch** with product URL
2. **Click "Visual Selector"** button
3. **Click on price element** on the rendered page
4. **Copy generated selector**
5. **Test it**

### Method 3: Browser Console

```javascript
// Test selector in browser console (F12 → Console)
document.querySelector('._30jeq3._16Jk6d').textContent
// Should return: "₹1,999" or similar
```

---

## Troubleshooting

### Selector Not Working

**Problem:** Old selector stopped working
**Cause:** Site redesign, A/B testing
**Solution:**
1. Inspect page with DevTools
2. Find new selector
3. Update in ChangeDetection.io

### Multiple Prices Showing

**Problem:** Multiple prices on page (MRP, Sale Price, etc.)
**Solution:**
```css
/* Be more specific */
.pricing-container .current-price .value
```

### JavaScript-Heavy Sites Not Loading

**Problem:** Price not appearing, blank page
**Solution:**
1. Enable Playwright ✅
2. Increase "Wait time" to 3-5 seconds
3. Check playwright-chrome container is running

### Price in Wrong Format

**Problem:** Getting "₹1,999" but want "1999"
**Solution:** Use text filter regex
```
Filter: ₹?([\d,]+)
Extract: Group 1
```

---

## Quick Reference Card

**Copy-paste ready selectors:**

```css
/* Flipkart */
._30jeq3._16Jk6d          /* Current price */
.B_NuCI                   /* Product title */
._16FRp0                  /* Availability */

/* Myntra */
.pdp-price strong         /* Current price */
.pdp-title                /* Product title */
.pdp-discount             /* Discount % */

/* Amazon India */
.a-price-whole            /* Current price */
#productTitle             /* Product title */
#availability span        /* Stock status */
```

---

## Updates & Maintenance

**Selector Validation Schedule:**
- Check selectors monthly
- Update after major site redesigns
- Test during sale events (Big Billion Days, etc.)

**How to contribute:**
- If you find working selectors, document them
- Share alternative selectors that work
- Report broken selectors

---

**Last Updated:** 2026-02-15
**Note:** Selectors may change as sites update their design. Test regularly.
