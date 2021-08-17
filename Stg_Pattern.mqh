/**
 * @file
 * Implements Pattern strategy based on the Pattern indicator.
 */

// User input params.
INPUT_GROUP("Pattern strategy: strategy params");
INPUT float Pattern_LotSize = 0;                // Lot size
INPUT int Pattern_SignalOpenMethod = 0;         // Signal open method
INPUT float Pattern_SignalOpenLevel = 0;        // Signal open level
INPUT int Pattern_SignalOpenFilterMethod = 32;  // Signal open filter method
INPUT int Pattern_SignalOpenFilterTime = 8;     // Signal open filter time (0-31)
INPUT int Pattern_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT int Pattern_SignalCloseMethod = 0;        // Signal close method
INPUT int Pattern_SignalCloseFilter = 32;       // Signal close filter (-127-127)
INPUT float Pattern_SignalCloseLevel = 0;       // Signal close level
INPUT int Pattern_PriceStopMethod = 0;          // Price limit method
INPUT float Pattern_PriceStopLevel = 2;         // Price limit level
INPUT int Pattern_TickFilterMethod = 1;         // Tick filter method (0-255)
INPUT float Pattern_MaxSpread = 4.0;            // Max spread to trade (in pips)
INPUT short Pattern_Shift = 0;                  // Shift
INPUT float Pattern_OrderCloseLoss = 0;         // Order close loss
INPUT float Pattern_OrderCloseProfit = 0;       // Order close profit
INPUT int Pattern_OrderCloseTime = -30;         // Order close time in mins (>0) or bars (<0)
INPUT_GROUP("Pattern strategy: Pattern indicator params");
INPUT int Pattern_Indi_Pattern_Shift = 1;  // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_Pattern_Params_Defaults : IndiPatternParams {
  Indi_Pattern_Params_Defaults() : IndiPatternParams(::Pattern_Indi_Pattern_Shift) {}
} indi_pattern_defaults;

// Defines struct with default user strategy values.
struct Stg_Pattern_Params_Defaults : StgParams {
  Stg_Pattern_Params_Defaults()
      : StgParams(::Pattern_SignalOpenMethod, ::Pattern_SignalOpenFilterMethod, ::Pattern_SignalOpenLevel,
                  ::Pattern_SignalOpenBoostMethod, ::Pattern_SignalCloseMethod, ::Pattern_SignalCloseFilter,
                  ::Pattern_SignalCloseLevel, ::Pattern_PriceStopMethod, ::Pattern_PriceStopLevel,
                  ::Pattern_TickFilterMethod, ::Pattern_MaxSpread, ::Pattern_Shift) {
    Set(STRAT_PARAM_OCL, Pattern_OrderCloseLoss);
    Set(STRAT_PARAM_OCP, Pattern_OrderCloseProfit);
    Set(STRAT_PARAM_OCT, Pattern_OrderCloseTime);
    Set(STRAT_PARAM_SOFT, Pattern_SignalOpenFilterTime);
  }
} stg_pattern_defaults;

#ifdef __config__
// Loads pair specific param values.
#include "config/H1.h"
#include "config/H4.h"
#include "config/H8.h"
#include "config/M1.h"
#include "config/M15.h"
#include "config/M30.h"
#include "config/M5.h"
#endif

class Stg_Pattern : public Strategy {
 public:
  Stg_Pattern(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_Pattern *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    IndiPatternParams _indi_params(indi_pattern_defaults, _tf);
    StgParams _stg_params(stg_pattern_defaults);
#ifdef __config__
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_pattern_m1, stg_pattern_m5, stg_pattern_m15, stg_pattern_m30,
                             stg_pattern_h1, stg_pattern_h4, stg_pattern_h8);
#endif
    // Initialize indicator.
    _stg_params.SetIndicator(new Indi_Pattern(_indi_params));
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams(_magic_no, _log_level);
    Strategy *_strat = new Stg_Pattern(_stg_params, _tparams, _cparams, "Pattern");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method, float _level = 0.0f, int _shift = 0) {
    Indi_Pattern *_indi = GetIndicator();
    bool _result =
        _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift) && _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift + 2);
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    IndicatorDataEntry _entry = _indi[_shift];
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        // Buy signal.
        switch (_method / 32) {
          case 5:
            _result &= (_entry.GetValue<int>(5) & 1 << ((_method - 1) / 32 * 5)) != 0;
            break;
          case 4:
            _result &= (_entry.GetValue<int>(4) & 1 << ((_method - 1) / 32 * 4)) != 0;
            break;
          case 3:
            _result &= (_entry.GetValue<int>(3) & 1 << ((_method - 1) / 32 * 3)) != 0;
            break;
          case 2:
            _result &= (_entry.GetValue<int>(2) & 1 << ((_method - 1) / 32 * 2)) != 0;
            break;
          case 1:
            _result &= (_entry.GetValue<int>(1) & 1 << ((_method - 1) / 32 * 1)) != 0;
            break;
          case 0:
            _result &= (_entry.GetValue<int>(0) & 1 << (_method - 1)) != 0;
            break;
        }
        break;
      case ORDER_TYPE_SELL:
        // Sell signal.
        switch (_method / 1000 / 32) {
          case 5:
            _result &= (_entry.GetValue<int>(5) & 1 << ((_method - 1000) / 1000 - 32 * 5)) != 0;
            break;
          case 4:
            _result &= (_entry.GetValue<int>(4) & 1 << ((_method - 1000) / 1000 - 32 * 4)) != 0;
            break;
          case 3:
            _result &= (_entry.GetValue<int>(3) & 1 << ((_method - 1000) / 1000 - 32 * 3)) != 0;
            break;
          case 2:
            _result &= (_entry.GetValue<int>(2) & 1 << ((_method - 1000) / 1000 - 32 * 2)) != 0;
            break;
          case 1:
            _result &= (_entry.GetValue<int>(1) & 1 << ((_method - 1000) / 1000 - 32 * 1)) != 0;
            break;
          case 0:
            _result &= (_entry.GetValue<int>(0) & 1 << ((_method - 1000) / 1000)) != 0;
            break;
        }
        break;
    }
    return _result;
  }
};
