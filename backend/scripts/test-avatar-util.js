/**
 * Test suite for avatar utilities
 */

const { generateAvatarColor, getAvatarInitial } = require('../utils/avatarUtil');

function testAvatarUtil() {
  console.log('Testing avatar utilities...\n');

  // Test 1: Avatar color generation
  console.log('Test 1: Avatar Color Generation');
  const user1 = 'alice';
  const color1 = generateAvatarColor(user1);
  console.log(`  User: "${user1}" -> Color: ${color1}`);

  const user2 = 'bob';
  const color2 = generateAvatarColor(user2);
  console.log(`  User: "${user2}" -> Color: ${color2}`);

  // Test 2: Deterministic color (same user = same color)
  console.log('\nTest 2: Deterministic Color');
  const color1Again = generateAvatarColor(user1);
  const matches = color1 === color1Again;
  console.log(`  "${user1}" produces same color twice: ${matches ? '✓ PASS' : '✗ FAIL'}`);
  if (!matches) console.log(`    First:  ${color1}`);
  if (!matches) console.log(`    Second: ${color1Again}`);

  // Test 3: Different users = different colors
  console.log('\nTest 3: Different Users Get Different Colors');
  const different = color1 !== color2;
  console.log(`  "${user1}" and "${user2}" have different colors: ${different ? '✓ PASS' : '✗ FAIL (may rarely fail by chance)'}`);

  // Test 4: Avatar initial extraction
  console.log('\nTest 4: Avatar Initial Extraction');
  const initial1 = getAvatarInitial(user1);
  const initial2 = getAvatarInitial(user2);
  console.log(`  User: "${user1}" -> Initial: "${initial1}"`);
  console.log(`  User: "${user2}" -> Initial: "${initial2}"`);
  console.log(`  Initials are uppercase: ${initial1 === initial1.toUpperCase() && initial2 === initial2.toUpperCase() ? '✓ PASS' : '✗ FAIL'}`);

  // Test 5: Edge cases
  console.log('\nTest 5: Edge Cases');
  console.log(`  Empty string initial: "${getAvatarInitial('')}"`);
  console.log(`  Lowercase conversion: "${getAvatarInitial('xyz')}"`);

  // Test 6: Color format validation
  console.log('\nTest 6: Color Format Validation');
  const colorRegex = /^#[0-9A-F]{6}$/;
  const isValidFormat = colorRegex.test(color1) && colorRegex.test(color2);
  console.log(`  Colors are valid hex format: ${isValidFormat ? '✓ PASS' : '✗ FAIL'}`);
  console.log(`    ${color1} - ${colorRegex.test(color1) ? '✓' : '✗'}`);
  console.log(`    ${color2} - ${colorRegex.test(color2) ? '✓' : '✗'}`);

  console.log('\n✓ All avatar utility tests completed!');
}

testAvatarUtil();
