%% @doc
%% A module to validate Erlang's records.
%%
%% The rvalidator module aims to take away the boilerplate of implementing validating functions,
%% while being agnostic of the verification rules and error handling practices.
%%
%% This module is based on the idea that a Record should have its own verification specification.
%% Since a Record is an aggregates of multiple fields, a Specification for a Record is implemented
%% as a set of constraints per field.
%%
%% @end
%%
%% @author Gaston Siffert

-module(rvalidator).

-export([
    constraint/2,
    required_field/4,
    optional_field/3
]).
-export([
    validate/2
]).

-type error() :: any().
%% The error to be raised by the constraint, the type is intentionaly open
%% to suits your needs but we do have some recommendation:
%% ```
%% invalid_name,
%% <<"InvalidName">>,
%% {name_too_long, MaxLength}
%% '''
%%
%% In general, the error should have a unique identifier and
%% if relevant to the constraint you could embed its configuration.

-type constraint_function() :: fun((any()) -> boolean()).
%% The constraint function implement the verification rules used to validate the Records.
%% The functions must return true if the Record complies to the rule and false otherwise. 

-record(constraint, {
    function :: constraint_function(),
    error :: error()
}).

-type field_name() :: any().
%% The field_name is used as a convenient placeholder to group the generated errors
%% under a same bucket. Most of the time the Name is expected to be
%% the same than the Record's field name, but occasionaly, it might be more
%% adequate to use a String, for example on the verification of a JSON.

-record(field_spec, {
    name :: field_name(),
    index :: non_neg_integer(),
    is_required = false :: boolean(),
    missing_error :: error(),
    constraints :: list(#constraint{})
}).

%%%----------------------------------------------------------------------------
%%% Functions to build the specification.
%%%----------------------------------------------------------------------------

%% @doc
%% Create a new constraint.
%%
%% A constraint illustrate the concept of rules to attach on a record
%% to verify its integrity.
%%
%% Example:
%% ```
%% validator:constraint(fun erlang:is_binary/1, not_binary).
%% validator:constraint(fun(X) -> size(X) =:= 2 end, {equal_length, 2}).
%% '''
%%
%% @end
%%
%% @param Function implements the rule to be verified.
%% @param Err define the error to be raised on verification failure.

-spec constraint(constraint_function(), error()) -> #constraint{}.
constraint(Function, Err) ->
    #constraint{function = Function, error = Err}.

%% @doc
%% Create the specification for a required field.
%%
%% A required field specification must define:
%% <ul>
%%  <li>the field's name</li>
%%  <li>the field's index in the Record</li>
%%  <li>the field's error if the value is undefined</li>
%%  <li>the field's constraints</li>
%% </ul>
%%
%% Example:
%% ```
%% validator:required_field(country_code, #country.country_code, missing_country_code, [
%%    validator:constraint(fun erlang:is_binary/1, not_binary),
%%    validator:constraint(fun(X) -> size(X) =:= 2 end, {equal_length, 2})
%% ]).
%% '''
%%
%% @end
%%
%% @param Name define the key which will be used to groups the errors. 
%% @param Index of the field in the Record.
%% @param MissingErr error to be raised if the required field is undefined.
%% @param Constraints to be verified.

-spec required_field(field_name(), non_neg_integer(), error(), list(#constraint{})) -> #field_spec{}.
required_field(Name, Index, MissingErr, Constraints) ->
    #field_spec{
        name = Name,
        index = Index,
        is_required = true,
        missing_error = MissingErr,
        constraints = Constraints
    }.

%% @doc
%% Create the specification for an optional field.
%%
%% An optional field specification must define:
%% <ul>
%%  <li>the field's name</li>
%%  <li>the field's index in the Record</li>
%%  <li>the field's constraints</li>
%% </ul>
%%
%% If the value of an optional field is undefined, then the validator module
%% won't verify its constraints.
%% Example:
%% ```
%% validator:optional_field(currency_code, #country.currency_code, [
%%    validator:constraint(fun erlang:is_binary/1, not_binary),
%%    validator:constraint(fun(X) -> size(X) =:= 3 end, {equal_length, 3})
%% ])
%% '''
%%
%% @end
%%
%% @param Name define the key which will be used to groups the errors. 
%% @param Index of the field in the Record.
%% @param Constraints to be verified.

-spec optional_field(field_name(), non_neg_integer(), list(#constraint{})) -> #field_spec{}.
optional_field(Name, Index, Constraints) ->
    #field_spec{
        name = Name,
        index = Index,
        is_required = false,
        constraints = Constraints
    }.

%%%----------------------------------------------------------------------------
%%% Functions to validate a Record against its Spec.
%%%----------------------------------------------------------------------------

%% @doc
%% Validate a Record against its specification.
%%
%% @end
%%
%% @param Record holds the data to validate.
%% @param FieldSpecs is a list of field specifications.
%% @see required_field/4
%% @see optional_field/3

-type field_errors() :: {field_name(), nonempty_list(error())}.
-type validate_result() :: ok | {error, nonempty_list(field_errors())}.
-spec validate(tuple(), list(#field_spec{})) -> validate_result().
validate(Record, FieldSpecs) ->
    Errors = lists:foldl(
        fun(Spec, Acc) ->
            validate_fold(element(Spec#field_spec.index, Record), Spec, Acc) 
        end,
        [],
        FieldSpecs
    ),
    case Errors of
        [] -> ok;
        _ -> {error, Errors}
    end.

%%%----------------------------------------------------------------------------
%%% Private functions
%%%----------------------------------------------------------------------------

validate_fold(undefined, #field_spec{is_required = false}, Acc) -> Acc;
validate_fold(undefined, #field_spec{name = Name, is_required = true, missing_error = Error}, Acc) ->
    [{Name, [Error]} | Acc];
validate_fold(Value, #field_spec{name = Name, constraints = Constraints}, Acc) ->
    Errors = lists:foldl(
        fun(#constraint{function = Function, error = Error}, NextAcc) ->
            case Function(Value) of
                true -> NextAcc;
                false -> [Error | NextAcc]
            end
        end,
        [],
        Constraints
    ),
    case Errors of
        [] -> Acc;
        _ -> [{Name, Errors} | Acc]
    end.
