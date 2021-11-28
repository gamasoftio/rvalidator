-module(rvalidator_test).

-include_lib("eunit/include/eunit.hrl").

-record(country, {
    name,
    country_code,
    currency_code
}).

validate_test_() ->
    Tests = [
        {
            "Missing required name",
            [
                rvalidator:required_field(name, #country.name, missing_name, []),
                rvalidator:required_field(country_code, #country.country_code, missing_country_code, [])
            ],
            #country{country_code = <<"NL">>},
            {error, [{name, [missing_name]}]}
        },
        {
            "Missing required country_code",
            [
                rvalidator:required_field(name, #country.name, missing_name, []),
                rvalidator:required_field(country_code, #country.country_code, missing_country_code, [])
            ],
            #country{name = <<"Netherlands">>},
            {error, [{country_code, [missing_country_code]}]}
        },
        {
            "Missing optional currency_code",
            [
                rvalidator:required_field(name, #country.name, missing_name, []),
                rvalidator:required_field(country_code, #country.country_code, missing_country_code, [])
            ],
            #country{name = <<"Netherlands">>, country_code = <<"NL">>},
            ok
        },
        {
            "currency_code with multiple errors",
            [
                rvalidator:required_field(name, #country.name, missing_name, [
                    rvalidator:constraint(fun erlang:is_binary/1, not_binary)
                ]),
                rvalidator:required_field(country_code, #country.country_code, missing_country_code, [
                    rvalidator:constraint(fun erlang:is_binary/1, not_binary),
                    rvalidator:constraint(fun(X) -> size(X) =:= 2 end, {equal_length, 2})
                ]),
                rvalidator:optional_field(currency_code, #country.currency_code, [
                    rvalidator:constraint(fun erlang:is_number/1, not_number),
                    rvalidator:constraint(fun(X) -> size(X) =:= 3 end, {equal_length, 3})
                ])
            ],
            #country{name = <<"Netherlands">>, country_code = <<"NL">>, currency_code = <<"EURO">>},
            {error, [{currency_code,[{equal_length,3},not_number]}]}
        },
        {
            "Valid record",
            [
                rvalidator:required_field(name, #country.name, missing_name, [
                    rvalidator:constraint(fun erlang:is_binary/1, not_binary)
                ]),
                rvalidator:required_field(country_code, #country.country_code, missing_country_code, [
                    rvalidator:constraint(fun erlang:is_binary/1, not_binary),
                    rvalidator:constraint(fun(X) -> size(X) =:= 2 end, {equal_length, 2})
                ]),
                rvalidator:optional_field(currency_code, #country.currency_code, [
                    rvalidator:constraint(fun erlang:is_binary/1, not_number),
                    rvalidator:constraint(fun(X) -> size(X) =:= 3 end, {equal_length, 3})
                ])
            ],
            #country{name = <<"Netherlands">>, country_code = <<"NL">>, currency_code = <<"EUR">>},
            ok
        }
    ],
    [
        {
            TestName,
            ?_assertEqual(Expected, rvalidator:validate(Record, Spec))
        }
        ||
        {TestName, Spec, Record, Expected} <- Tests
    ].
