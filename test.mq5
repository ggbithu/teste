//|                                          SMT Plínio Rodrigues.mq5 |
//|                        SMT Plínio Rodrigues, Dev Geilson Santana. |
//|                                                    @geilson_minas |
//+------------------------------------------------------------------+

#property copyright "Plínio_Rodrigues_Dev:@geilson_minas"
#property link      "+55(31)99525.5369"
#property version   "1.00"

#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\Trade.mqh>

CSymbolInfo m_symbol;
CPositionInfo pos;
CTrade m_trade;
COrderInfo m_order;

input string firstSymbol = "USDX.a"; // Definir o primeiro ativo
input string secondSymbol = "EURUSD#"; // Definir o segundo ativo
input int input_distance_min = 18; // Distância mínima entre as velas
input int input_distance_max = 18; // Distância máxima entre as velas
input double min_point_difference = 0; // Diferença mínima de pontos entre o primeiro e o segundo topo

input double entrada_input = 20;  // Valor do lote
input double stopLossPoints = 35;  // Valor do stop loss em pontos
input double takeProfitPoints = 100; // Valor do take profit em pontos

double lastFirstTop = 0.0; // Armazena o último valor do primeiro topo
double lastSecondTop = 0.0; // Armazena o último valor do segundo topo
double lastFirstBottom = 0.0; // Armazena o último valor do primeiro fundo
double lastSecondBottom = 0.0; // Armazena o último valor do segundo fundo

datetime firstTopTime = 0; // Armazena o horário da vela do primeiro topo
double firstTopValue = 0.0; // Armazena o valor do primeiro topo
datetime secondTopTime = 0; // Armazena o horário da vela do segundo topo
double secondTopValue = 0.0; // Armazena o valor do segundo topo
bool isTopValid = false; // Indica se os valores de topo são válidos

datetime firstBottomTime = 0; // Armazena o horário da vela do primeiro fundo
double firstBottomValue = 0.0; // Armazena o valor do primeiro fundo
datetime secondBottomTime = 0; // Armazena o horário da vela do segundo fundo
double secondBottomValue = 0.0; // Armazena o valor do segundo fundo
bool isBottomValid = false; // Indica se os valores de fundo são válidos

double minVolume;
double maxVolume;
double stepVolume;

// Defina o limite máximo de operações diárias desejado
input int limiteOperacoesDia = 1;
datetime currentDay = 0;
int operationsCounter = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    EventSetTimer(300); // Define o intervalo de verificação como 300 segundos (5 minutos)

    m_symbol.Name(secondSymbol);
    m_symbol.Refresh();
    m_symbol.RefreshRates();

    minVolume = m_symbol.LotsMin();
    maxVolume = m_symbol.LotsMax();
    stepVolume = m_symbol.LotsStep();

    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer(); // Encerra o timer ao finalizar o Expert Advisor
}

//+------------------------------------------------------------------+
//| Função para verificar e imprimir os topos                        |
//+------------------------------------------------------------------+
void CheckAndPrintTops(int distance)
{
    int total_bars = Bars(firstSymbol, _Period);

    // Assegurar que existem barras suficientes para processar
    if (total_bars >= distance)
    {
        double HighArray[];
        ArraySetAsSeries(HighArray, true);

        // Pegar os valores de High das últimas "distance" velas
        CopyHigh(firstSymbol, _Period, 0, distance, HighArray);

        double firstTop = HighArray[distance - 1]; // Primeiro topo
        double secondTop = HighArray[0];                 // Segundo topo
        bool isValid = true;

        // Verificar se entre o primeiro e segundo topo há alguma vela maior que a vela 1
        for (int i = distance - 2; i >= 1; i--)
        {
            if (HighArray[i] > firstTop)
            {
                isValid = false;
                break;
            }
        }

        // Verificar se o segundo topo é mais alto que o primeiro
        if (secondTop <= firstTop)
        {
            isValid = false;
        }

        // Verificar se a diferença entre o segundo topo e o primeiro topo é maior que a diferença mínima de pontos
        if ((secondTop - firstTop) < min_point_difference * m_symbol.Point())
        {
            isValid = false;
        }

        // Se é válido e os topos são diferentes dos valores anteriores
        if (isValid && (firstTop != lastFirstTop || secondTop != lastSecondTop))
        {
            // Verificar se as velas entre a vela 1 e a vela 15 são menores ou iguais à vela 1
            bool areCandlesValid = true;
            for (int i = distance - 2; i >= 1; i--)
            {
                if (HighArray[i] > firstTop)
                {
                    areCandlesValid = false;
                    break;
                }
            }

            if (areCandlesValid)
            {
                firstTopTime = iTime(firstSymbol, _Period, distance - 1); // Armazena o horário da vela do primeiro topo
                firstTopValue = firstTop; // Armazena o valor do primeiro topo

                secondTopTime = iTime(firstSymbol, _Period, 0); // Armazena o horário da vela do segundo topo
                secondTopValue = secondTop; // Armazena o valor do segundo topo

                isTopValid = true; // Indica que os valores de topo são válidos

                lastFirstTop = firstTop; // Atualiza o valor do último primeiro topo
                lastSecondTop = secondTop; // Atualiza o valor do último segundo topo
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Função para verificar e imprimir os fundos                       |
//+------------------------------------------------------------------+
void CheckAndPrintBottoms(int distance)
{
    int total_bars = Bars(firstSymbol, _Period);

    // Assegurar que existem barras suficientes para processar
    if (total_bars >= distance)
    {
        double LowArray[];
        ArraySetAsSeries(LowArray, true);

        // Pegar os valores de Low das últimas "distance" velas
        CopyLow(firstSymbol, _Period, 0, distance, LowArray);

        double firstBottom = LowArray[distance - 1]; // Primeiro fundo
        double secondBottom = LowArray[0];                 // Segundo fundo
        bool isValid = true;

        // Verificar se entre o primeiro e segundo fundo há alguma vela menor que a vela 1
        for (int i = distance - 2; i >= 1; i--)
        {
            if (LowArray[i] < firstBottom)
            {
                isValid = false;
                break;
            }
        }

        // Verificar se o segundo fundo é menor que o primeiro
        if (secondBottom >= firstBottom)
        {
            isValid = false;
        }

        // Verificar se a diferença entre o primeiro fundo e o segundo fundo é maior que a diferença mínima de pontos
        if ((firstBottom - secondBottom) < min_point_difference * m_symbol.Point())
        {
            isValid = false;
        }

        // Se é válido e os fundos são diferentes dos valores anteriores
        if (isValid && (firstBottom != lastFirstBottom || secondBottom != lastSecondBottom))
        {
            // Verificar se as velas entre a vela 1 e a vela 15 são maiores ou iguais à vela 1
            bool areCandlesValid = true;
            for (int i = distance - 2; i >= 1; i--)
            {
                if (LowArray[i] < firstBottom)
                {
                    areCandlesValid = false;
                    break;
                }
            }

            if (areCandlesValid)
            {
                firstBottomTime = iTime(firstSymbol, _Period, distance - 1); // Armazena o horário da vela do primeiro fundo
                firstBottomValue = firstBottom; // Armazena o valor do primeiro fundo

                secondBottomTime = iTime(firstSymbol, _Period, 0); // Armazena o horário da vela do segundo fundo
                secondBottomValue = secondBottom; // Armazena o valor do segundo fundo

                isBottomValid = true; // Indica que os valores de fundo são válidos

                lastFirstBottom = firstBottom; // Atualiza o valor do último primeiro fundo
                lastSecondBottom = secondBottom; // Atualiza o valor do último segundo fundo
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Função para imprimir os topos do segundo ativo no mesmo horário  |
//| e criar as linhas correspondentes                                 |
//+------------------------------------------------------------------+
void PrintTopsAtTime(string symbol, datetime firstTime, datetime secondTime)
{
    double firstTop = iHigh(symbol, _Period, iBarShift(symbol, _Period, firstTime));
    double secondTop = iHigh(symbol, _Period, iBarShift(symbol, _Period, secondTime));

    Print("No ativo ", symbol, " Primeiro Topo em: ", TimeToString(firstTime), " Valor: ", firstTop);
    Print("No ativo ", symbol, " Segundo Topo em: ", TimeToString(secondTime), " Valor: ", secondTop);

    bool areCandlesValid = true;

    // Verificar se alguma vela entre o primeiro e o segundo topo é maior que o segundo topo
    for (int i = iBarShift(symbol, _Period, firstTime) - 1; i > iBarShift(symbol, _Period, secondTime); i--)
    {
        double candleHigh = iHigh(symbol, _Period, i);
        if (candleHigh > secondTop)
        {
            areCandlesValid = false;
            break;
        }
    }

    // Verificar se o segundo topo é menor que o primeiro topo e se todas as velas entre eles são válidas
    if (secondTop < firstTop && areCandlesValid)
    {
        Print("SINAL VENDA");
        OpenSel(m_symbol, entrada_input, stopLossPoints, takeProfitPoints);

        // Criar linhas nos gráficos correspondentes
        string lineName1 = "Line_" + TimeToString(firstTime, TIME_DATE | TIME_MINUTES);
        string lineName2 = "Line_" + TimeToString(secondTime, TIME_DATE | TIME_MINUTES);

        if (ObjectFind(0, lineName1) != -1)
        {
            ObjectDelete(0, lineName1);
        }

        if (ObjectFind(0, lineName2) != -1)
        {
            ObjectDelete(0, lineName2);
        }

        ObjectCreate(0, lineName1, OBJ_TREND, 0, firstTime, firstTop, secondTime, secondTop);
        ObjectSetInteger(0, lineName1, OBJPROP_COLOR, clrRed);
        ObjectSetInteger(0, lineName1, OBJPROP_WIDTH, 2);

        ObjectCreate(0, lineName2, OBJ_TREND, 0, secondTime, secondTop, secondTime, secondTop);
        ObjectSetInteger(0, lineName2, OBJPROP_COLOR, clrRed);
        ObjectSetInteger(0, lineName2, OBJPROP_WIDTH, 2);
    }
    else
    {
        // Condição inválida, aguardar próxima condição
        return;
    }
}


//+------------------------------------------------------------------+
//| Função para imprimir os fundos do segundo ativo no mesmo horário |
//+------------------------------------------------------------------+
void PrintBottomsAtTime(string symbol, datetime firstTime, datetime secondTime)
{
    double firstBottom = iLow(symbol, _Period, iBarShift(symbol, _Period, firstTime));
    double secondBottom = iLow(symbol, _Period, iBarShift(symbol, _Period, secondTime));

    Print("No ativo ", symbol, " Primeiro Fundo em: ", TimeToString(firstTime), " Valor: ", firstBottom);
    Print("No ativo ", symbol, " Segundo Fundo em: ", TimeToString(secondTime), " Valor: ", secondBottom);

    bool areCandlesValid = true;

    // Verificar se alguma vela entre o primeiro e o segundo fundo é menor que o segundo fundo
    for (int i = iBarShift(symbol, _Period, firstTime) - 1; i > iBarShift(symbol, _Period, secondTime); i--)
    {
        double candleLow = iLow(symbol, _Period, i);
        if (candleLow < secondBottom)
        {
            areCandlesValid = false;
            break;
        }
    }

    // Verificar se o segundo fundo é maior que o primeiro fundo, se todas as velas entre eles são válidas e imprimir "SINAL COMPRA" se verdadeiro
    if (secondBottom > firstBottom && areCandlesValid)
    {
        Print("SINAL COMPRA");
        OpenBuy(m_symbol, entrada_input, stopLossPoints, takeProfitPoints);

        // Criar linhas nos gráficos correspondentes
        string lineName1 = "Line_" + TimeToString(firstTime, TIME_DATE | TIME_MINUTES);
        string lineName2 = "Line_" + TimeToString(secondTime, TIME_DATE | TIME_MINUTES);

        if (ObjectFind(0, lineName1) != -1)
        {
            ObjectDelete(0, lineName1);
        }

        if (ObjectFind(0, lineName2) != -1)
        {
            ObjectDelete(0, lineName2);
        }

        ObjectCreate(0, lineName1, OBJ_TREND, 0, firstTime, firstBottom, secondTime, secondBottom);
        ObjectSetInteger(0, lineName1, OBJPROP_COLOR, clrGreen);
        ObjectSetInteger(0, lineName1, OBJPROP_WIDTH, 2);

        ObjectCreate(0, lineName2, OBJ_TREND, 0, secondTime, secondBottom, secondTime, secondBottom);
        ObjectSetInteger(0, lineName2, OBJPROP_COLOR, clrGreen);
        ObjectSetInteger(0, lineName2, OBJPROP_WIDTH, 2);
    }
    else
    {
        // Condição inválida, aguardar próxima condição
        return;
    }
}



//+------------------------------------------------------------------+
//| Função chamada a cada novo tick                                  |
//+------------------------------------------------------------------+
void OnTick()
{
    m_symbol.Refresh();
    m_symbol.RefreshRates();

    MqlDateTime currentDateTime;
    TimeToStruct(TimeCurrent(), currentDateTime);

    int currentHour = currentDateTime.hour;

    // Verificar se está dentro do horário de funcionamento (6:00 - 14:00 +6h no GMT-3)
    if (currentHour >= 6 && currentHour < 14)
    {
        // Verificar se houve uma mudança de dia
        if (currentDateTime.day != currentDay)
        {
            // Houve uma mudança de dia, redefinir o contador de operações
            currentDay = currentDateTime.day;
            operationsCounter = 0;
        }

        // Loop para verificar os padrões de reversão em cada valor de distância dentro da faixa
        for (int distance = input_distance_min; distance <= input_distance_max; distance++)
        {
            CheckAndPrintTops(distance);
            CheckAndPrintBottoms(distance);
        }
    }
}

//+------------------------------------------------------------------+
//| Função chamada a cada intervalo de tempo definido                |
//+------------------------------------------------------------------+
void OnTimer()
{
    if (isTopValid)
    {
        Print("Primeiro Topo: ", TimeToString(firstTopTime), " Valor: ", firstTopValue);
        Print("Segundo Topo: ", TimeToString(secondTopTime), " Valor: ", secondTopValue);

        PrintBottomsAtTime(secondSymbol, firstTopTime, secondTopTime); // Imprime os fundos no mesmo horário dos topos

        isTopValid = false; // Reinicia a validação dos topos
    }

    if (isBottomValid)
    {
        Print("Primeiro Fundo: ", TimeToString(firstBottomTime), " Valor: ", firstBottomValue);
        Print("Segundo Fundo: ", TimeToString(secondBottomTime), " Valor: ", secondBottomValue);

        PrintTopsAtTime(secondSymbol, firstBottomTime, secondBottomTime); // Imprime os topos no mesmo horário dos fundos

        isBottomValid = false; // Reinicia a validação dos fundos
    }
}

//+------------------------------------------------------------------+
//| Função para abrir uma ordem de venda                              |
//+------------------------------------------------------------------+
void OpenSel(CSymbolInfo &Symbol, double entrada, double slPoints, double tpPoints)
{
    double price = Symbol.Bid();
    double stopLoss = 0.0;
    if (slPoints > 0) stopLoss = price + slPoints * Symbol.Point();
    double takeProfit = 0.0;
    if (tpPoints > 0) takeProfit = price - tpPoints * Symbol.Point();

    // Verifica se o limite de operações diárias foi atingido
    if (operationsCounter >= limiteOperacoesDia)
    {
        Print("Limite de operações diárias atingido. Não é possível abrir mais operações.");
        return; // Retorna sem abrir uma nova ordem
    }

    if (m_trade.PositionOpen(Symbol.Name(), ORDER_TYPE_SELL, AjustaVolume(Symbol, entrada), price, stopLoss, takeProfit))
    
    {
        Print("Ordem de venda aberta com sucesso!");
        operationsCounter++; // Incrementa o contador de operações
    }
    else
    {
        Print("Erro ao abrir a ordem de venda. Código do erro: ", m_trade.ResultRetcode());
    }
}

//+------------------------------------------------------------------+
//| Função para abrir uma ordem de compra                             |
//+------------------------------------------------------------------+
void OpenBuy(CSymbolInfo &Symbol, double entrada, double slPoints, double tpPoints)
{
    double price = Symbol.Ask();
    double stopLoss = 0.0;
    if (slPoints > 0) stopLoss = price - slPoints * Symbol.Point();
    double takeProfit = 0.0;
    if (tpPoints > 0) takeProfit = price + tpPoints * Symbol.Point();

    // Verifica se o limite de operações diárias foi atingido
    if (operationsCounter >= limiteOperacoesDia)
    {
        Print("Limite de operações diárias atingido. Não é possível abrir mais operações.");
        return; // Retorna sem abrir uma nova ordem
    }

    if (m_trade.PositionOpen(Symbol.Name(), ORDER_TYPE_BUY, AjustaVolume(Symbol, entrada), price, stopLoss, takeProfit))
    {
        Print("Ordem de compra aberta com sucesso!");
        operationsCounter++; // Incrementa o contador de operações
    }
    else
    {
        Print("Erro ao abrir a ordem de compra. Código do erro: ", m_trade.ResultRetcode());
    }
}

double AjustaVolume(CSymbolInfo &Symbol, double volume)
{
    // Limite inferior
    if (volume < minVolume)
    {
        return minVolume;
    }

    // Limite superior
    if (volume > maxVolume)
    {
        return maxVolume;
    }

    // Valor Válido
    int ratio = (int)MathRound(volume / stepVolume);
    if ((ratio * stepVolume) != volume)
    {
        return NormalizeDouble((ratio * stepVolume), Symbol.Digits());
    }
    return NormalizeDouble(volume, Symbol.Digits());
}
