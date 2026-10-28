# Publicação na loja Connect IQ

Painel: <https://apps.garmin.com/en-US/developer/upload> (login com a conta Garmin Connect).

## IDs do app

| Uso | ID | Onde |
|---|---|---|
| **Público** (loja) | `0f5749dfd853474d903b0fb423eca5c0` | `apps/garmin-field/manifest.xml` |
| **Beta** (só o desenvolvedor) | `57f461f2d3ee4be3b634396faf99f336` | trocado só no build Beta |

A Garmin não deixa um app Beta virar o app publicado, por isso os IDs são diferentes.

## Gerar o pacote Beta (FR255 Music)

Copie `apps/garmin-field` para uma pasta temporária, troque o `id` do manifesto pelo ID Beta, deixe só o
produto `fr255m` e exporte:

```sh
monkeyc -e -r -f monkey.jungle -o FuelUp-beta.iq -y developer_key.der
```

Envie com a versão (ex.: `0.1.0`) e **Aplicativo Beta** marcado. A cada novo Beta, suba a versão.

## Versão pública

1. Baixar no SDK Manager todos os modelos do manifesto (`fr255`, `fr255m`, `fr255s`, `fr255sm`).
2. Exportar com o manifesto do repositório (ID público), sem marcar Beta.
3. Página da loja: descrição, ícone, screenshots e o aviso “sugestões gerais, não é prescrição”.

## Chave de assinatura

Todas as versões precisam ser assinadas com a mesma `developer_key.der`
(`C:\Users\mtreb\.garmin\`). Guarde um backup fora do computador: sem ela não dá para atualizar o app.
