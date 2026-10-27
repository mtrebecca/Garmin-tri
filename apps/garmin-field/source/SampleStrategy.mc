import Toybox.Lang;

// Estratégia fixa para o POC, com intervalos curtos para testar no simulador.
// Mesmo formato que o backend vai enviar (ver docs/contrato-estrategia.md).
module SampleStrategy {

    function get() as Dictionary {
        return {
            "v" => 1,
            "id" => "00000000-0000-0000-0000-000000000001",
            "name" => "POC teste",
            "items" => [
                { "t" => 60, "p" => "Gel 25g", "c" => 25, "na" => 50, "ml" => 0 },
                { "t" => 180, "p" => "Isotonico 500ml", "c" => 30, "na" => 300, "ml" => 500 },
                { "t" => 300, "p" => "Gel 25g", "c" => 25, "na" => 50, "ml" => 0 }
            ]
        };
    }
}
