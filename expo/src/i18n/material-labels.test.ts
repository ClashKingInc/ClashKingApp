import {
  materialBackLabel,
  materialCloseLabel,
  materialContinueLabel,
  materialNextMonthTooltip,
  materialNextPageTooltip,
  materialPreviousMonthTooltip,
  materialPreviousPageTooltip,
} from './material-labels';

describe('Flutter Material labels', () => {
  it('preserves regional English and Spanish fallback behavior', () => {
    expect(materialContinueLabel('en_GB')).toBe('Continue');
    expect(materialContinueLabel('en_US')).toBe('Continue');
    expect(materialContinueLabel('es_ES')).toBe('Continuar');
  });

  it('preserves RTL and CJK labels', () => {
    expect(materialContinueLabel('ar')).toBe('المتابعة');
    expect(materialContinueLabel('he')).toBe('המשך');
    expect(materialContinueLabel('hi')).toBe('जारी रखें');
    expect(materialContinueLabel('ja')).toBe('続行');
    expect(materialContinueLabel('ur')).toBe('جاری رکھیں');
    expect(materialContinueLabel('zh')).toBe('继续');
  });

  it('preserves Flutter Material back tooltips', () => {
    expect(materialBackLabel('en_GB')).toBe('Back');
    expect(materialBackLabel('ar')).toBe('رجوع');
    expect(materialBackLabel('he')).toBe('הקודם');
    expect(materialBackLabel('ja')).toBe('戻る');
    expect(materialBackLabel('zh')).toBe('返回');
  });

  it('preserves Flutter Material calendar and close labels', () => {
    expect(materialPreviousMonthTooltip('en_GB')).toBe('Previous month');
    expect(materialNextMonthTooltip('ar')).toBe('الشهر التالي');
    expect(materialPreviousMonthTooltip('ja')).toBe('前月');
    expect(materialNextMonthTooltip('zh')).toBe('下个月');
    expect(materialCloseLabel('fr')).toBe('Fermer');
    expect(materialCloseLabel('ur')).toBe('بند کریں');
  });

  it('preserves Flutter Material page tooltips', () => {
    expect(materialPreviousPageTooltip('ar')).toBe('الصفحة السابقة');
    expect(materialNextPageTooltip('hi')).toBe('अगला पेज');
    expect(materialPreviousPageTooltip('en_GB')).toBe('Previous page');
  });
});
